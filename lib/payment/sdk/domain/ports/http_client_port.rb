# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Ports
        module HttpClientPort
          def request(method:, path:, headers: {}, body: nil, query_params: {})
            raise NotImplementedError, "#{self.class} must implement #request"
          end
        end
      end
    end
  end
end
