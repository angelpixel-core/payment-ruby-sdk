# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/reconciliation/ports/mismatch/reporter"

class DomainReconciliationPortsMismatchReporterTest < Minitest::Test
  class UnimplementedReporter
    include Payment::SDK::Domain::Reconciliation::Ports::Mismatch::Reporter
  end

  def setup
    @reporter = UnimplementedReporter.new
  end

  def test_report_raises_not_implemented
    assert_raises(NotImplementedError) do
      @reporter.report(snapshot: { status: :status_drift })
    end
  end
end
