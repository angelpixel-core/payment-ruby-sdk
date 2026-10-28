# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "payment/sdk/shared/domain/ports/http/client"
require "payment/sdk/errors"
require "payment/sdk/infrastructure/adapters/http/error_mapper"
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

              # @param base_url [String] base URL of the API (trailing slash is stripped)
              # @param open_timeout [Numeric] connection open timeout in seconds
              # @param read_timeout [Numeric] read timeout in seconds
              # @param max_retries [Integer] maximum number of retry attempts
              def initialize(base_url:, open_timeout: 30, read_timeout: 80, max_retries: 2)
                @base_url = base_url.sub(%r{/$}, "")
                @open_timeout = open_timeout
                @read_timeout = read_timeout
                @max_retries = max_retries
              end

              # Performs an HTTP request with automatic retries on transient errors.
              #
              # @param method [Symbol, String] HTTP method (`:get`, `:post`, `:put`, `:delete`)
              # @param path [String] relative endpoint path
              # @param headers [Hash] custom HTTP headers
              # @param body [Hash, nil] optional request body serialized as JSON
              # @param query_params [Hash] optional URL query parameters
              # @return [Hash, Array, String, nil] parsed JSON response with symbolized keys, raw body, or `nil`
              # @raise [ArgumentError] when `method` is unsupported
              # @raise [Payment::SDK::ApiError] when the server responds with a non-2xx status
              # @raise [Payment::SDK::TimeoutError] when the request times out after retries
              # @raise [Payment::SDK::NetworkError] when a socket/transport error persists after retries
              def request(method:, path:, headers: {}, body: nil, query_params: {})
                uri = build_uri(path, query_params)
                req = build_request(method, uri, headers, body)

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

              def build_request(method, uri, custom_headers, body)
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

                req.body = JSON.generate(body) if body
                req
              end

              def execute_with_retries(uri, req)
                retries = 0

                begin
                  perform_request(uri, req)
                rescue Payment::SDK::NetworkError, Payment::SDK::TimeoutError, Payment::SDK::UpstreamError => e
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

                response = begin
                  http.request(req)
                rescue Net::OpenTimeout, Net::ReadTimeout
                  raise Payment::SDK::TimeoutError, "Request to #{uri} timed out"
                rescue StandardError => e
                  raise Payment::SDK::NetworkError, "Network error during request to #{uri}: #{e.message}"
                end

                ErrorMapper.map_error(response)

                return nil if response.body.nil? || response.body.empty?

                JSON.parse(response.body, symbolize_names: true)
              rescue JSON::ParserError
                response.body
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
