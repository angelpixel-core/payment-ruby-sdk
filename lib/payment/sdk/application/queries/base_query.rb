# frozen_string_literal: true

module Payment
  module SDK
    module Application
      module Queries
        class BaseQuery
          attr_reader :http_client

          def initialize(http_client)
            @http_client = http_client
          end
        end
      end
    end
  end
end
