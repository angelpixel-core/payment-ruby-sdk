# frozen_string_literal: true

require "payment/sdk/shared/application/base_query"

module Payment
  module SDK
    module Refunds
      module Application
        module Queries
          class Get < Shared::Application::BaseQuery
            def call(id:)
              http_client.request(
                method: :get,
                path: "/refunds/#{id}"
              )
            end
          end
        end
      end
    end
  end
end
