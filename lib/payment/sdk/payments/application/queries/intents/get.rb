# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Payments
      module Application
        # Read-only queries of the payments bounded context.
        module Queries
          # Queries operating on payment intents.
          module Intents
            # Query that fetches a payment intent by ID (`GET /payment_intents/:id`).
            class Get < Shared::Application::BaseQuery
              # @param id [String] payment intent identifier (`pi_...`)
              # @return [Hash] parsed payment intent payload
              def call(id:)
                http_client.request(
                  method: :get,
                  path: "/payment_intents/#{id}"
                )
              end
            end
          end
        end
      end
    end
  end
end
