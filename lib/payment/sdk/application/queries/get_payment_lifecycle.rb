# frozen_string_literal: true

require "payment/sdk/application/queries/base_query"

module Payment
  module SDK
    module Application
      module Queries
        class GetPaymentLifecycle < BaseQuery
          def execute(id:)
            http_client.request(
              method: :get,
              path: "/payment_intents/#{id}/lifecycle"
            )
          end
        end
      end
    end
  end
end
