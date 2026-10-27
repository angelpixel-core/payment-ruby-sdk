# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Shared
        module Ports
          module Http
            module Client
              def request(method:, path:, headers: {}, body: nil, query_params: {})
                raise NotImplementedError, "#{self.class} must implement #request"
              end
            end
          end
        end
      end
    end
  end
end
