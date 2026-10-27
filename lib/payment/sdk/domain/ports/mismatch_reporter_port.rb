# frozen_string_literal: true

require "payment/sdk/domain/reconciliation/ports/mismatch/reporter"

module Payment
  module SDK
    module Domain
      module Ports
        MismatchReporterPort = Payment::SDK::Domain::Reconciliation::Ports::Mismatch::Reporter
      end
    end
  end
end
