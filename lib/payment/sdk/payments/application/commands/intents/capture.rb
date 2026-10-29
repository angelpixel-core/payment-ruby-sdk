# frozen_string_literal: true

require "payment/sdk/shared/application/base_command"

module Payment
  module SDK
    module Payments
      module Application
        module Commands
          module Intents
            # Command that captures authorized funds for a payment intent (`POST /payment_intents/:id/capture`).
            class Capture < Shared::Application::BaseCommand
              # @param id [String] payment intent identifier (`pi_...`)
              # @param amount [Integer, nil] optional partial capture amount in minor units
              # @param idempotency_key [String, Shared::Domain::ValueObjects::IdempotencyKey] mandatory idempotency key
              # @param request_id [String, nil] optional request identifier for distributed tracing
              # @param traceparent [String, nil] optional W3C traceparent header
              # @param headers [Hash] optional additional HTTP headers
              # @return [Hash] parsed API response
              # @raise [ArgumentError] when `idempotency_key` is missing or empty
              def call(id:, amount: nil, idempotency_key: nil, request_id: nil, traceparent: nil, headers: {})
                req_headers = build_headers(
                  idempotency_key: idempotency_key,
                  request_id: request_id,
                  traceparent: traceparent,
                  headers: headers
                )

                body = {}
                body[:amount] = amount if amount

                http_client.request(
                  method: :post,
                  path: "/payment_intents/#{id}/capture",
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
