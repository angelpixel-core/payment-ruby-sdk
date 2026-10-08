# frozen_string_literal: true

require "payment/sdk/application/queries/base_query"

module Payment
  module SDK
    module Application
      module Queries
        class GetPaymentAttempt < BaseQuery
          def execute(id:)
            http_client.request(
              method: :get,
              path: "/payment_attempts/#{id}"
            )
          end
        end
      end
    end
  end
end
