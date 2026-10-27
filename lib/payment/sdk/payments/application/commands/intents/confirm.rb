# frozen_string_literal: true

require "payment/sdk/shared/application/base_command"

module Payment
  module SDK
    module Payments
      module Application
        module Commands
          module Intents
            class Confirm < Shared::Application::BaseCommand
              def call(id:, payment_method_token:, idempotency_key: nil, scenario: nil)
                key = normalize_idempotency_key(idempotency_key)

                headers = {
                  "Idempotency-Key" => key.value
                }
                headers["X-Sandbox-Scenario"] = scenario if scenario

                body = {
                  payment_method_token: payment_method_token
                }

                http_client.request(
                  method: :post,
                  path: "/payment_intents/#{id}/confirm",
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
