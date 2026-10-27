# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Reconciliation
        module Ports
          module Mismatch
            module Reporter
              def report(snapshot:)
                raise NotImplementedError, "#{self.class} must implement #report"
              end
            end
          end
        end
      end
    end
  end
end
