# frozen_string_literal: true

require "payment/sdk/reconciliation/domain/ports/mismatch/reporter"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        # Reporting adapters for reconciliation drift.
        module Reporting
          # Mismatch reporting adapters.
          module Mismatch
            # Mismatch reporter implementations.
            module Reporter
              # Thread-safe in-memory implementation of {Payment::SDK::Reconciliation::Domain::Ports::Mismatch::Reporter}.
              class InMemory
                include Reconciliation::Domain::Ports::Mismatch::Reporter

                # @return [Array<Hash>] accumulated non-matching reconciliation snapshot entries
                attr_reader :reports

                # Initializes an empty mutex-synchronized mismatch reporter.
                def initialize
                  @reports = []
                  @mutex = Mutex.new
                end

                # Records the snapshot when its status is not `:match`.
                #
                # @param snapshot [Hash, #status] reconciliation snapshot entry
                # @return [void]
                def report(snapshot:)
                  status = snapshot_status(snapshot)
                  return if status == :match

                  @mutex.synchronize do
                    @reports << snapshot.dup
                  end
                end

                # Clears all recorded mismatch reports.
                #
                # @return [Array]
                def clear!
                  @mutex.synchronize { @reports.clear }
                end

                private

                def snapshot_status(snapshot)
                  if snapshot.respond_to?(:status)
                    snapshot.status
                  elsif snapshot.respond_to?(:[])
                    snapshot[:status]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
