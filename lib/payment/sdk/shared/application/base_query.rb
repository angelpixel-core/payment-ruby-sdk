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
        end
      end
    end
  end
end
