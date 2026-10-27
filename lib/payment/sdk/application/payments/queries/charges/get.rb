# frozen_string_literal: true

require "payment/sdk/application/shared/base_query"

module Payment
  module SDK
    module Application
      module Payments
        module Queries
          module Charges
            class Get < Shared::BaseQuery
              def execute(id:)
                http_client.request(
                  method: :get,
                  path: "/charges/#{id}"
                )
              end
            end
          end
        end
      end
    end
  end
end
