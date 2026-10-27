# frozen_string_literal: true

require "payment/sdk/reconciliation/domain/ports/mismatch/reporter"
require "thread"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        module Reporting
          module Mismatch
            module Reporter
              class InMemory
                include Reconciliation::Domain::Ports::Mismatch::Reporter

                attr_reader :reports

                def initialize
                  @reports = []
                  @mutex = Mutex.new
                end

                def report(snapshot:)
                  status = snapshot_status(snapshot)
                  return if status == :match

                  @mutex.synchronize do
                    @reports << snapshot.dup
                  end
                end

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
