# frozen_string_literal: true

module Payment
  module SDK
    module Shared
      module Application
        # Abstract base class for read-only CQRS queries.
        #
        # Subclasses must implement {#call}.
        class BaseQuery
          # @return [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP client port
          attr_reader :http_client

          # @param http_client [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP client port
          def initialize(http_client)
            @http_client = http_client
          end

          # Executes the query.
          #
          # @param options [Hash] query keyword arguments
          # @return [Object] query result
          # @raise [NotImplementedError] when not overridden by a subclass
          def call(**options)
            raise NotImplementedError, "#{self.class} must implement #call"
          end

          protected

          # Builds standard HTTP headers including distributed tracing identifiers.
          #
          # @param request_id [String, nil] optional correlation identifier
          # @param traceparent [String, nil] optional W3C trace context header
          # @param headers [Hash] additional custom headers
          # @return [Hash{String => String}] merged headers
          def build_headers(request_id: nil, traceparent: nil, headers: {})
            merged = headers.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v.to_s }
            merged["X-Request-Id"] = request_id.to_s if request_id
            merged["traceparent"] = traceparent.to_s if traceparent
            merged
          end
        end
      end
    end
  end
end
