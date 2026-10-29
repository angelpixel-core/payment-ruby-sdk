# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Payments
      module Application
        module Queries
          # Queries operating on payment intent lifecycles.
          module Lifecycles
            # Query that fetches the lifecycle audit trail of a payment intent
            # (`GET /payment_intents/:id/lifecycle`).
            class Get < Shared::Application::BaseQuery
              # @param id [String] payment intent identifier (`pi_...`)
              # @param request_id [String, nil] optional request identifier for distributed tracing
              # @param traceparent [String, nil] optional W3C traceparent header
              # @param headers [Hash] optional additional HTTP headers
              # @return [Hash] parsed lifecycle payload
              def call(id:, request_id: nil, traceparent: nil, headers: {})
                req_headers = build_headers(request_id: request_id, traceparent: traceparent, headers: headers)
                http_client.request(
                  method: :get,
                  path: "/payment_intents/#{id}/lifecycle",
                  headers: req_headers
                )
              end
            end
          end
        end
      end
    end
  end
end
