# frozen_string_literal: true

require "test_helper"
require "payment/sdk/application/reconciliation/use_cases/reconcile"
require "payment/sdk/infrastructure/adapters/persistence/snapshot/store/in_memory"
require "payment/sdk/infrastructure/adapters/reporting/mismatch/reporter/in_memory"

class ApplicationReconciliationUseCasesReconcileTest < Minitest::Test
  class StubSnapshotClient
    attr_accessor :remote_records

    def initialize(records = [])
      @remote_records = records
    end

    def get_transaction_snapshot
      @remote_records.map(&:dup)
    end
  end

  def setup
    @client = StubSnapshotClient.new
    @store = Payment::SDK::Infrastructure::Adapters::Persistence::Snapshot::Store::InMemory.new
    @reporter = Payment::SDK::Infrastructure::Adapters::Reporting::Mismatch::Reporter::InMemory.new
    @use_case = Payment::SDK::Application::Reconciliation::UseCases::Reconcile.new(
      snapshot_client: @client,
      snapshot_store: @store,
      mismatch_reporter: @reporter
    )

    @base_record = {
      payment_intent_id: "pi_100",
      status: "succeeded",
      amount: 5000,
      currency: "usd",
      latest_attempt_id: "pa_100",
      captured_amount: 5000,
      refunded_amount: 0
    }
  end

  def test_perfect_match
    @client.remote_records = [@base_record]
    results = @use_case.call(local_records: [@base_record], run_id: "run_alpha")

    assert_equal 1, results.size
    assert_equal :match, results.first[:status]
    assert_equal "run_alpha:pi_100", results.first[:id]
    assert_equal 1, @store.all.size
    assert_empty @reporter.reports
  end

  def test_status_drift
    remote = @base_record.merge(status: "failed")
    @client.remote_records = [remote]

    results = @use_case.call(local_records: [@base_record], run_id: "run_beta")

    assert_equal :status_drift, results.first[:status]
    assert_equal 1, @reporter.reports.size
  end

  def test_amount_drift
    remote = @base_record.merge(amount: 2500)
    @client.remote_records = [remote]

    results = @use_case.call(local_records: [@base_record], run_id: "run_gamma")

    assert_equal :amount_drift, results.first[:status]
    assert_equal 1, @reporter.reports.size
  end

  def test_attempt_drift
    remote = @base_record.merge(latest_attempt_id: "pa_other")
    @client.remote_records = [remote]

    results = @use_case.call(local_records: [@base_record], run_id: "run_delta")

    assert_equal :attempt_drift, results.first[:status]
  end

  def test_capture_drift
    remote = @base_record.merge(captured_amount: 2500)
    @client.remote_records = [remote]

    results = @use_case.call(local_records: [@base_record], run_id: "run_eps")

    assert_equal :capture_drift, results.first[:status]
  end

  def test_refund_drift
    remote = @base_record.merge(refunded_amount: 1000)
    @client.remote_records = [remote]

    results = @use_case.call(local_records: [@base_record], run_id: "run_zeta")

    assert_equal :refund_drift, results.first[:status]
  end

  def test_missing_local
    @client.remote_records = [@base_record]
    results = @use_case.call(local_records: [], run_id: "run_eta")

    assert_equal :missing_local, results.first[:status]
  end

  def test_missing_remote
    @client.remote_records = []
    results = @use_case.call(local_records: [@base_record], run_id: "run_theta")

    assert_equal :missing_remote, results.first[:status]
  end

  def test_idempotent_runs_overwrite_store_entry
    @client.remote_records = [@base_record]
    @use_case.call(local_records: [@base_record], run_id: "run_idem")
    @use_case.call(local_records: [@base_record], run_id: "run_idem")

    assert_equal 1, @store.all.size
  end
end
