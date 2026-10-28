# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Reconciliation
      module Application
        module Queries
          # Queries operating on deterministic transaction snapshots.
          module Snapshots
            # Query that fetches a deterministic transaction snapshot
            # (`GET /reports/transactions?view=snapshot`).
            class Get < Shared::Application::BaseQuery
              # @param start_date [String, nil] optional ISO date/time lower bound
              # @param end_date [String, nil] optional ISO date/time upper bound
              # @return [Array<Hash>, Hash] parsed transaction snapshot payload
              def call(start_date: nil, end_date: nil)
                query_params = { view: "snapshot" }
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
