# frozen_string_literal: true

module Payment
  module SDK
    module Shared
      module Application
        class BaseQuery
          attr_reader :http_client

          def initialize(http_client)
            @http_client = http_client
          end

          def call(**options)
            raise NotImplementedError, "#{self.class} must implement #call"
          end
        end
      end
    end
  end
end
