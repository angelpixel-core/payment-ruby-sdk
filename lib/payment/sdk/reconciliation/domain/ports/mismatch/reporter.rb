# frozen_string_literal: true

module Payment
  module SDK
    # Reconciliation bounded context (financial drift detection, snapshots, and reports).
    module Reconciliation
      # Domain layer of the reconciliation bounded context.
      module Domain
        # Secondary ports of the reconciliation bounded context.
        module Ports
          # Financial drift mismatch reporting port namespace.
          module Mismatch
            # Secondary port defining the contract for reporting reconciliation mismatches.
            module Reporter
              # Reports a reconciliation snapshot entry when drift is detected.
              #
              # @param snapshot [Hash] reconciliation snapshot entry
              # @return [void]
              # @raise [NotImplementedError] when not implemented by an adapter
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
