# frozen_string_literal: true

require "payment/sdk/shared/application/base_command"

module Payment
  module SDK
    module Payments
      module Application
        module Commands
          module Intents
            class Capture < Shared::Application::BaseCommand
              def call(id:, amount: nil, idempotency_key: nil)
                key = normalize_idempotency_key(idempotency_key)

                headers = {
                  "Idempotency-Key" => key.value
                }

                body = {}
                body[:amount] = amount if amount

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
