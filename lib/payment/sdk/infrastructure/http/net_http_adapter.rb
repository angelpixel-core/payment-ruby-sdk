# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "payment/sdk/domain/ports/http_client_port"
require "payment/sdk/errors"
require "payment/sdk/infrastructure/http/error_mapper"
require "payment/sdk/version"

module Payment
  module SDK
    module Infrastructure
      module Http
        class NetHttpAdapter
          include Payment::SDK::Domain::Ports::HttpClientPort

          def initialize(base_url:, open_timeout: 30, read_timeout: 80, max_retries: 2)
            @base_url = base_url.sub(%r{/$}, "")
            @open_timeout = open_timeout
            @read_timeout = read_timeout
            @max_retries = max_retries
          end

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
            sleep_time = (2 ** (retry_count - 1)) + rand(0.0..0.5)
            sleep(sleep_time)
          end
        end
      end
    end
  end
end
