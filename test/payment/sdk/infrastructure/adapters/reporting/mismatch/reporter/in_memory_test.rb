# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/reporting/mismatch/reporter/in_memory"

class InfrastructureAdaptersReportingMismatchReporterInMemoryTest < Minitest::Test
  def setup
    @reporter = Payment::SDK::Infrastructure::Adapters::Reporting::Mismatch::Reporter::InMemory.new
  end

  def test_report_mismatch_appends_to_reports
    @reporter.report(snapshot: { id: "snap_1", status: :status_drift })
    assert_equal 1, @reporter.reports.size
    assert_equal :status_drift, @reporter.reports.first[:status]
  end

  def test_report_ignores_perfect_matches
    @reporter.report(snapshot: { id: "snap_1", status: :match })
    assert_empty @reporter.reports
  end

  def test_report_dup_isolation
    snapshot = { id: "snap_1", status: :amount_drift }
    @reporter.report(snapshot: snapshot)

    snapshot[:status] = :match
    assert_equal :amount_drift, @reporter.reports.first[:status]
  end

  def test_clear_empties_reports
    @reporter.report(snapshot: { id: "snap_1", status: :amount_drift })
    @reporter.clear!
    assert_empty @reporter.reports
  end

  def test_thread_safety
    threads = 10.times.map do |i|
      Thread.new do
        @reporter.report(snapshot: { id: "snap_#{i}", status: :drift, index: i })
      end
    end
    threads.each(&:join)

    assert_equal 10, @reporter.reports.size
  end
end
