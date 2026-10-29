# frozen_string_literal: true

require "payment/sdk/shared/application/base_command"
require "payment/sdk/shared/domain/value_objects/money"

module Payment
  module SDK
    module Payments
      # Application layer of the payments bounded context.
      module Application
        # State-mutating commands of the payments bounded context.
        module Commands
          # Commands operating on payment intents.
          module Intents
            # Command that creates a new payment intent (`POST /payment_intents`).
            class Create < Shared::Application::BaseCommand
              # @param amount [Integer] amount in minor currency units
              # @param currency [String, Symbol, Shared::Domain::ValueObjects::Currency] 3-letter ISO currency code
              # @param merchant_id [String, nil] optional merchant identifier
              # @param customer_id [String, nil] optional customer identifier
              # @param capture_method [String] `"automatic"` or `"manual"`
              # @param idempotency_key [String, Shared::Domain::ValueObjects::IdempotencyKey] mandatory idempotency key
              # @param metadata [Hash] optional key-value metadata
              # @param request_id [String, nil] optional request identifier for distributed tracing
              # @param traceparent [String, nil] optional W3C traceparent header
              # @param headers [Hash] optional additional HTTP headers
              # @return [Hash] parsed API response
              # @raise [ArgumentError] when `idempotency_key`, `amount`, or `currency` is invalid
              def call(amount:, currency:, merchant_id: nil, customer_id: nil, capture_method: "automatic", idempotency_key: nil, metadata: {}, request_id: nil, traceparent: nil, headers: {})
                req_headers = build_headers(
                  idempotency_key: idempotency_key,
                  request_id: request_id,
                  traceparent: traceparent,
                  headers: headers
                )
                money = Shared::Domain::ValueObjects::Money.new(amount, currency)

                body = {
                  amount: money.amount,
                  currency: money.currency.code,
                  capture_method: capture_method,
                  metadata: metadata
                }
                body[:merchant_id] = merchant_id if merchant_id
                body[:customer_id] = customer_id if customer_id

                http_client.request(
                  method: :post,
                  path: "/payment_intents",
                  headers: req_headers,
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
