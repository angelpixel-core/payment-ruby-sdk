# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Ports
        module SignatureVerifierPort
          def verify(payload:, signature:, secret:, timestamp_tolerance: 300)
            raise NotImplementedError, "#{self.class} must implement #verify"
          end
        end
      end
    end
  end
end
