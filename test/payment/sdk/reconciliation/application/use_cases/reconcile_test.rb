# frozen_string_literal: true

require "test_helper"
require "payment/sdk/reconciliation/application/use_cases/reconcile"
require "payment/sdk/infrastructure/adapters/persistence/snapshot/store/in_memory"
require "payment/sdk/infrastructure/adapters/reporting/mismatch/reporter/in_memory"

class ReconciliationApplicationUseCasesReconcileTest < Minitest::Test
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
    @use_case = Payment::SDK::Reconciliation::Application::UseCases::Reconcile.new(
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
end
