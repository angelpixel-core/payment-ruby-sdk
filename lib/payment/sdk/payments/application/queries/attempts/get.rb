# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Payments
      module Application
        module Queries
          # Queries operating on payment attempts.
          module Attempts
            # Query that fetches a payment attempt by ID (`GET /payment_attempts/:id`).
            class Get < Shared::Application::BaseQuery
              # @param id [String] payment attempt identifier (`pa_...`)
              # @return [Hash] parsed payment attempt payload
              def call(id:)
                http_client.request(
                  method: :get,
                  path: "/payment_attempts/#{id}"
                )
              end
            end
          end
        end
      end
    end
  end
end
