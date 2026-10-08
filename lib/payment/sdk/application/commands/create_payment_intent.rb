# frozen_string_literal: true

require "payment/sdk/application/commands/base_command"

module Payment
  module SDK
    module Application
      module Commands
        class CreatePaymentIntent < BaseCommand
          def execute(amount:, currency:, merchant_id:, customer_id:, capture_method:, idempotency_key:)
            headers = default_headers(idempotency_key)
            
            body = {
              amount: amount,
              currency: currency.to_s.downcase,
              merchant_id: merchant_id,
              customer_id: customer_id,
              capture_method: capture_method
            }
            
            http_client.request(
              method: :post,
              path: "/payment_intents",
              headers: headers,
              body: body
            )
          end
        end
      end
    end
  end
end
