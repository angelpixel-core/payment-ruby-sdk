# frozen_string_literal: true

require "payment/sdk/application/commands/base_command"

module Payment
  module SDK
    module Application
      module Commands
        class ConfirmPaymentIntent < BaseCommand
          def execute(id:, payment_method_token:, idempotency_key:, scenario: nil)
            headers = default_headers(idempotency_key)
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
