# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Refunds
      module Application
        # Read-only queries of the refunds bounded context.
        module Queries
          # Query that fetches a refund by ID (`GET /refunds/:id`).
          class Get < Shared::Application::BaseQuery
            # @param id [String] refund identifier (`re_...`)
            # @return [Hash] parsed refund payload
            def call(id:)
              http_client.request(
                method: :get,
                path: "/refunds/#{id}"
              )
            end
          end
        end
      end
    end
  end
end
