# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Reconciliation
      # Application layer of the reconciliation bounded context.
      module Application
        # Read-only queries of the reconciliation bounded context.
        module Queries
          # Queries operating on canonical transaction reports.
          module Reports
            # Query that fetches a transaction report (`GET /reports/transactions`).
            class Get < Shared::Application::BaseQuery
              # @param start_date [String, nil] optional ISO date/time lower bound
              # @param end_date [String, nil] optional ISO date/time upper bound
              # @param request_id [String, nil] optional request identifier for distributed tracing
              # @param traceparent [String, nil] optional W3C traceparent header
              # @param headers [Hash] optional additional HTTP headers
              # @return [Array<Hash>, Hash] parsed transaction report payload
              def call(start_date: nil, end_date: nil, request_id: nil, traceparent: nil, headers: {})
                query_params = {}
                query_params[:start_date] = start_date if start_date
                query_params[:end_date] = end_date if end_date

                req_headers = build_headers(request_id: request_id, traceparent: traceparent, headers: headers)

                http_client.request(
                  method: :get,
                  path: "/reports/transactions",
                  headers: req_headers,
                  query_params: query_params
                )
              end
            end
          end
        end
      end
    end
  end
end
