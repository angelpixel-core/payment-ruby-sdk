# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Payments
      module Application
        module Queries
          # Queries operating on charges.
          module Charges
            # Query that fetches a charge by ID (`GET /charges/:id`).
            class Get < Shared::Application::BaseQuery
              # @param id [String] charge identifier (`ch_...`)
              # @return [Hash] parsed charge payload
              def call(id:)
                http_client.request(
                  method: :get,
                  path: "/charges/#{id}"
                )
              end
            end
          end
        end
      end
    end
  end
end
