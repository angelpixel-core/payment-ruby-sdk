# frozen_string_literal: true

require "payment/sdk/shared/application/base_command"
require "payment/sdk/shared/domain/value_objects/money"

module Payment
  module SDK
    module Payments
      module Application
        module Commands
          module Intents
            class Create < Shared::Application::BaseCommand
              def call(amount:, currency:, merchant_id: nil, customer_id: nil, capture_method: "automatic", idempotency_key: nil, metadata: {})
                key = normalize_idempotency_key(idempotency_key)
                money = Shared::Domain::ValueObjects::Money.new(amount, currency)

                body = {
                  amount: money.amount,
                  currency: money.currency.code,
                  capture_method: capture_method,
                  metadata: metadata
                }
                body[:merchant_id] = merchant_id if merchant_id
                body[:customer_id] = customer_id if customer_id

                headers = {
                  "Idempotency-Key" => key.value
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
  end
end
