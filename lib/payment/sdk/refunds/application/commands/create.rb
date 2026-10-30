# frozen_string_literal: true

require "payment/sdk/shared/application/base_command"

module Payment
  module SDK
    module Refunds
      # Application layer of the refunds bounded context.
      module Application
        # State-mutating commands of the refunds bounded context.
        module Commands
          # Command that issues a full or partial refund (`POST /refunds`).
          class Create < Shared::Application::BaseCommand
            # @param charge_id [String] charge identifier (`ch_...`)
            # @param amount [Integer, nil] optional partial refund amount in minor units
            # @param reason [String, nil] optional refund reason
            # @param idempotency_key [String, Shared::Domain::ValueObjects::IdempotencyKey] mandatory idempotency key
            # @param request_id [String, nil] optional request identifier for distributed tracing
            # @param traceparent [String, nil] optional W3C traceparent header
            # @param headers [Hash] optional additional HTTP headers
            # @return [Hash] parsed refund response payload
            # @raise [ArgumentError] when `idempotency_key` is missing or empty
            def call(charge_id:, amount: nil, reason: nil, idempotency_key: nil, request_id: nil, traceparent: nil, headers: {})
              req_headers = build_headers(
                idempotency_key: idempotency_key,
                request_id: request_id,
                traceparent: traceparent,
                headers: headers
              )

              body = {
                charge_id: charge_id
              }
              body[:amount] = amount if amount
              body[:reason] = reason if reason

              http_client.request(
                method: :post,
                path: "/refunds",
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
