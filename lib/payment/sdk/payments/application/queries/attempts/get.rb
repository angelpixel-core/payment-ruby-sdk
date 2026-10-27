# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Payments
      module Application
        module Queries
          module Attempts
            class Get < Shared::Application::BaseQuery
              def call(id:)
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
  end
end
