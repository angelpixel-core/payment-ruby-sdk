# frozen_string_literal: true

require "payment/sdk/infrastructure/adapters/reporting/mismatch/reporter/in_memory"

module Payment
  module SDK
    module Infrastructure
      module Reporting
        InMemoryMismatchReporter = Payment::SDK::Infrastructure::Adapters::Reporting::Mismatch::Reporter::InMemory
      end
    end
  end
end
