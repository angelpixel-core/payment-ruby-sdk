# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "payment/sdk/shared/domain/ports/http/client"
require "payment/sdk/errors"
require "payment/sdk/infrastructure/adapters/http/error_mapper"
require "payment/sdk/infrastructure/logging/sanitizer"
require "payment/sdk/version"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        # HTTP transport adapters and response error mappers.
        module Http
          # HTTP client adapter implementations.
          module Client
            # Standard-library `Net::HTTP` adapter with automatic exponential backoff
            # and jitter retries on {Payment::SDK::NetworkError}, {Payment::SDK::TimeoutError},
            # and {Payment::SDK::UpstreamError}.
            class NetHttp
              include Payment::SDK::Shared::Domain::Ports::Http::Client

              # @return [Object, nil] optional logger instance
              attr_reader :logger
              # @return [Payment::SDK::Infrastructure::Resilience::CircuitBreaker, nil] optional circuit breaker
              attr_reader :circuit_breaker
              # @return [Numeric] maximum delay in seconds to wait on 429 Retry-After
              attr_reader :rate_limit_max_delay

              # @param base_url [String] base URL of the API (trailing slash is stripped)
              # @param open_timeout [Numeric] connection open timeout in seconds
              # @param read_timeout [Numeric] read timeout in seconds
              # @param max_retries [Integer] maximum number of retry attempts
              # @param logger [Object, nil] optional logger responding to `#info`, `#warn`, `#error`, `#debug`
              # @param circuit_breaker [Payment::SDK::Infrastructure::Resilience::CircuitBreaker, nil] circuit breaker instance
              # @param rate_limit_max_delay [Numeric] maximum seconds to sleep when receiving HTTP 429 Retry-After
              def initialize(base_url:, open_timeout: 30, read_timeout: 80, max_retries: 2, logger: nil, circuit_breaker: nil, rate_limit_max_delay: 10)
                @base_url = base_url.sub(%r{/$}, "")
                @open_timeout = open_timeout
                @read_timeout = read_timeout
                @max_retries = max_retries
                @logger = logger
                @circuit_breaker = circuit_breaker
                @rate_limit_max_delay = rate_limit_max_delay
              end

              # Performs an HTTP request with automatic retries on transient errors.
              #
              # @param method [Symbol, String] HTTP method (`:get`, `:post`, `:put`, `:delete`)
              # @param path [String] relative endpoint path
              # @param headers [Hash] custom HTTP headers
              # @param body [Hash, nil] optional request body serialized as JSON
              # @param query_params [Hash] optional URL query parameters
              # @param request_id [String, nil] optional request identifier for distributed tracing
              # @param traceparent [String, nil] optional W3C traceparent header
              # @return [Hash, Array, String, nil] parsed JSON response with symbolized keys, raw body, or `nil`
              # @raise [ArgumentError] when `method` is unsupported
              # @raise [Payment::SDK::ApiError] when the server responds with a non-2xx status
              # @raise [Payment::SDK::TimeoutError] when the request times out after retries
              # @raise [Payment::SDK::NetworkError] when a socket/transport error persists after retries
              def request(method:, path:, headers: {}, body: nil, query_params: {}, request_id: nil, traceparent: nil)
                effective_request_id = request_id || headers["X-Request-Id"] || headers[:request_id]
                effective_traceparent = traceparent || headers["traceparent"] || headers[:traceparent]

                uri = build_uri(path, query_params)
                req = build_request(method, uri, headers, body, request_id: effective_request_id, traceparent: effective_traceparent)

                execute_with_retries(uri, req)
              end

              private

              def build_uri(path, query_params)
                uri = URI.parse("#{@base_url}#{path}")
                unless query_params.empty?
                  uri.query = URI.encode_www_form(query_params)
                end
                uri
              end

              def build_request(method, uri, custom_headers, body, request_id: nil, traceparent: nil)
                req_class = case method.to_s.downcase.to_sym
                when :get then Net::HTTP::Get
                when :post then Net::HTTP::Post
                when :put then Net::HTTP::Put
                when :delete then Net::HTTP::Delete
                else raise ArgumentError, "Unsupported HTTP method: #{method}"
                end

                req = req_class.new(uri)

                req["Content-Type"] = "application/json"
                req["User-Agent"] = "payment-ruby-sdk/#{Payment::SDK::VERSION}"

                custom_headers.each do |k, v|
                  req[k.to_s] = v.to_s
                end

                req["X-Request-Id"] = request_id.to_s if request_id && !req["X-Request-Id"]
                req["traceparent"] = traceparent.to_s if traceparent && !req["traceparent"]

                req.body = JSON.generate(body) if body
                req
              end

              def execute_with_retries(uri, req)
                retries = 0

                begin
                  @circuit_breaker&.check!
                  result = perform_request(uri, req)
                  @circuit_breaker&.record_success!
                  result
                rescue Payment::SDK::RateLimitError => e
                  if retries < @max_retries && e.retry_after_seconds && e.retry_after_seconds <= @rate_limit_max_delay
                    retries += 1
                    sleep(e.retry_after_seconds)
                    retry
                  else
                    raise e
                  end
                rescue Payment::SDK::NetworkError, Payment::SDK::TimeoutError, Payment::SDK::UpstreamError => e
                  @circuit_breaker&.record_failure!
                  if retries < @max_retries
                    retries += 1
                    sleep_for_backoff(retries)
                    retry
                  else
                    raise e
                  end
                end
              end

              def perform_request(uri, req)
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = (uri.scheme == "https")
                http.open_timeout = @open_timeout
                http.read_timeout = @read_timeout

                log_debug_request(req)

                start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
                response = begin
                  http.request(req)
                rescue Net::OpenTimeout, Net::ReadTimeout
                  duration_ms = calculate_duration_ms(start_time)
                  log_event(method: req.method, uri: uri, duration_ms: duration_ms, request_id: req["X-Request-Id"], error: "TimeoutError")
                  raise Payment::SDK::TimeoutError, "Request to #{uri} timed out"
                rescue => e
                  duration_ms = calculate_duration_ms(start_time)
                  log_event(method: req.method, uri: uri, duration_ms: duration_ms, request_id: req["X-Request-Id"], error: e.class.name)
                  raise Payment::SDK::NetworkError, "Network error during request to #{uri}: #{e.message}"
                end

                duration_ms = calculate_duration_ms(start_time)
                req_id = (response.respond_to?(:[]) ? response["x-request-id"] : nil) || req["X-Request-Id"]
                log_event(method: req.method, uri: uri, status: response.code.to_i, duration_ms: duration_ms, request_id: req_id)

                ErrorMapper.map_error(response)

                return nil if response.body.nil? || response.body.empty?

                JSON.parse(response.body, symbolize_names: true)
              rescue JSON::ParserError
                response.body
              end

              def log_event(method:, uri:, duration_ms:, status: nil, request_id: nil, error: nil)
                return unless @logger

                sanitized_url = Logging::Sanitizer.sanitize_url(uri)
                req_id_segment = request_id ? " request_id=#{request_id}" : ""

                if error
                  msg = "[Payment::SDK] method=#{method} url=\"#{sanitized_url}\" error=#{error} duration_ms=#{duration_ms}#{req_id_segment}"
                  @logger.warn(msg) if @logger.respond_to?(:warn)
                else
                  msg = "[Payment::SDK] method=#{method} url=\"#{sanitized_url}\" status=#{status} duration_ms=#{duration_ms}#{req_id_segment}"
                  if status && status >= 400
                    @logger.warn(msg) if @logger.respond_to?(:warn)
                  elsif @logger.respond_to?(:info)
                    @logger.info(msg)
                  end
                end
              end

              def log_debug_request(req)
                return unless @logger&.respond_to?(:debug)

                sanitized_headers = Logging::Sanitizer.sanitize_headers(req.to_hash)
                @logger.debug("[Payment::SDK] #{req.method} headers=#{sanitized_headers}")
              end

              def calculate_duration_ms(start_time)
                ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)
              end

              def sleep_for_backoff(retry_count)
                sleep_time = (2**(retry_count - 1)) + rand(0.0..0.5)
                sleep(sleep_time)
              end
            end
          end
        end
      end
    end
  end
end
