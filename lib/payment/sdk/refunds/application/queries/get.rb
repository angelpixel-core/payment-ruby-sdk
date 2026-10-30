# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Refunds
      module Application
        # Read-only queries of the refunds bounded context.
        module Queries
          # Query that fetches a refund by ID (`GET /refunds/:id`).
          class Get < Shared::Application::BaseQuery
            # @param id [String] refund identifier (`re_...`)
            # @param request_id [String, nil] optional request identifier for distributed tracing
            # @param traceparent [String, nil] optional W3C traceparent header
            # @param headers [Hash] optional additional HTTP headers
            # @return [Hash] parsed refund payload
            def call(id:, request_id: nil, traceparent: nil, headers: {})
              req_headers = build_headers(request_id: request_id, traceparent: traceparent, headers: headers)
              http_client.request(
                method: :get,
                path: "/refunds/#{id}",
                headers: req_headers
              )
            end
          end
        end
      end
    end
  end
end
