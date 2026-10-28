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
              # @return [Array<Hash>, Hash] parsed transaction report payload
              def call(start_date: nil, end_date: nil)
                query_params = {}
                query_params[:start_date] = start_date if start_date
                query_params[:end_date] = end_date if end_date

                http_client.request(
                  method: :get,
                  path: "/reports/transactions",
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
