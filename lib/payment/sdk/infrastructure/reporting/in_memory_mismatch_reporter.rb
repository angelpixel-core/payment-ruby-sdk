# frozen_string_literal: true

require "payment/sdk/domain/ports/mismatch_reporter_port"
require "thread"

module Payment
  module SDK
    module Infrastructure
      module Reporting
        class InMemoryMismatchReporter
          include Payment::SDK::Domain::Ports::MismatchReporterPort

          attr_reader :reports

          def initialize
            @reports = []
            @mutex = Mutex.new
          end

          def report(snapshot:)
            return if snapshot[:status] == :match

            @mutex.synchronize do
              @reports << snapshot.dup
            end
          end

          def clear!
            @mutex.synchronize { @reports.clear }
          end
        end
      end
    end
  end
end
