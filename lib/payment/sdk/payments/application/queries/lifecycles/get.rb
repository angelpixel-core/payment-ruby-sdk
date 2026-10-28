# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Payments
      module Application
        module Queries
          # Queries operating on payment intent lifecycles.
          module Lifecycles
            # Query that fetches the lifecycle audit trail of a payment intent
            # (`GET /payment_intents/:id/lifecycle`).
            class Get < Shared::Application::BaseQuery
              # @param id [String] payment intent identifier (`pi_...`)
              # @return [Hash] parsed lifecycle payload
              def call(id:)
                http_client.request(
                  method: :get,
                  path: "/payment_intents/#{id}/lifecycle"
                )
              end
            end
          end
        end
      end
    end
  end
end
