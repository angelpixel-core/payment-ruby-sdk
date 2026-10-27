# frozen_string_literal: true

require "payment/sdk/application/shared/base_command"

module Payment
  module SDK
    module Application
      module Payments
        module Commands
          module Intents
            class Capture < Shared::BaseCommand
              def execute(id:, amount:, idempotency_key:)
                headers = default_headers(idempotency_key)

                body = {
                  amount: amount
                }

                http_client.request(
                  method: :post,
                  path: "/payment_intents/#{id}/capture",
                  headers: headers,
                  body: body
                )
              end
            end
          end
        end
      end
    end
  end
end
