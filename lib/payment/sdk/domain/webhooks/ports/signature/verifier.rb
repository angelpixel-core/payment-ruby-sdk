# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Webhooks
        module Ports
          module Signature
            module Verifier
              def verify(payload:, signature:, secret:, timestamp_tolerance: 300)
                raise NotImplementedError, "#{self.class} must implement #verify"
              end
            end
          end
        end
      end
    end
  end
end
