# frozen_string_literal: true

module Payment
  module SDK
    module Shared
      module Domain
        # Abstract ports shared across bounded contexts.
        module Ports
          # HTTP transport port namespace.
          module Http
            # Secondary port defining the contract for HTTP transport adapters.
            module Client
              # Executes an HTTP request against the payment platform API.
              #
              # @param method [Symbol, String] HTTP method (`:get`, `:post`, `:put`, `:delete`)
              # @param path [String] relative API endpoint path
              # @param headers [Hash{String => String}] HTTP request headers
              # @param body [Hash, nil] request body payload to serialize as JSON
              # @param query_params [Hash] URL query string parameters
              # @return [Object] parsed response body
              # @raise [NotImplementedError] when not implemented by an adapter
              def request(method:, path:, headers: {}, body: nil, query_params: {})
                raise NotImplementedError, "#{self.class} must implement #request"
              end
            end
          end
        end
      end
    end
  end
end
