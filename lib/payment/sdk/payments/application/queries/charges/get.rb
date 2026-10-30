# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Payments
      module Application
        module Queries
          # Queries operating on charges.
          module Charges
            # Query that fetches a charge by ID (`GET /charges/:id`).
            class Get < Shared::Application::BaseQuery
              # @param id [String] charge identifier (`ch_...`)
              # @param request_id [String, nil] optional request identifier for distributed tracing
              # @param traceparent [String, nil] optional W3C traceparent header
              # @param headers [Hash] optional additional HTTP headers
              # @return [Hash] parsed charge payload
              def call(id:, request_id: nil, traceparent: nil, headers: {})
                req_headers = build_headers(request_id: request_id, traceparent: traceparent, headers: headers)
                http_client.request(
                  method: :get,
                  path: "/charges/#{id}",
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
