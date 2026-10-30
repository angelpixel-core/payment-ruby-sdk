# frozen_string_literal: true

require "payment/sdk/shared/application/base_command"

module Payment
  module SDK
    module Payments
      module Application
        module Commands
          module Intents
            # Command that confirms a payment intent (`POST /payment_intents/:id/confirm`).
            class Confirm < Shared::Application::BaseCommand
              # @param id [String] payment intent identifier (`pi_...`)
              # @param payment_method_token [String] payment method token
              # @param idempotency_key [String, Shared::Domain::ValueObjects::IdempotencyKey] mandatory idempotency key
              # @param scenario [String, nil] optional sandbox scenario header (`X-Sandbox-Scenario`)
              # @param request_id [String, nil] optional request identifier for distributed tracing
              # @param traceparent [String, nil] optional W3C traceparent header
              # @param headers [Hash] optional additional HTTP headers
              # @return [Hash] parsed API response
              # @raise [ArgumentError] when `idempotency_key` is missing or empty
              def call(id:, payment_method_token:, idempotency_key: nil, scenario: nil, request_id: nil, traceparent: nil, headers: {})
                req_headers = build_headers(
                  idempotency_key: idempotency_key,
                  request_id: request_id,
                  traceparent: traceparent,
                  headers: headers
                )
                req_headers["X-Sandbox-Scenario"] = scenario if scenario

                body = {
                  payment_method_token: payment_method_token
                }

                http_client.request(
                  method: :post,
                  path: "/payment_intents/#{id}/confirm",
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
