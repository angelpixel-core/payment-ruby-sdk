# frozen_string_literal: true

require "payment/sdk/application/queries/base_query"

module Payment
  module SDK
    module Application
      module Queries
        class GetTransactionReport < BaseQuery
          def execute(start_date: nil, end_date: nil)
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
