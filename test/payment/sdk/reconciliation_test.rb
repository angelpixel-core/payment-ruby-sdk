# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/persistence/in_memory_snapshot_store"
require "payment/sdk/infrastructure/reporting/in_memory_mismatch_reporter"
require "payment/sdk/application/use_cases/reconcile_transactions"

class MockSnapshotClient
  attr_accessor :remote_records

  def initialize
    @remote_records = []
  end

  def get_transaction_snapshot
    # Return a deep dup
    @remote_records.map(&:dup)
  end
end

class ReconciliationTest < Minitest::Test
  def setup
    @snapshot_client = MockSnapshotClient.new
    @store = Payment::SDK::Infrastructure::Persistence::InMemorySnapshotStore.new
    @reporter = Payment::SDK::Infrastructure::Reporting::InMemoryMismatchReporter.new
    
    @use_case = Payment::SDK::Application::UseCases::ReconcileTransactions.new(
      snapshot_client: @snapshot_client,
      snapshot_store: @store,
      mismatch_reporter: @reporter
    )
    
    @base_record = {
      payment_intent_id: "pi_123",
      status: "succeeded",
      amount: 1000,
      currency: "usd",
      latest_attempt_id: "pa_123",
      captured_amount: 1000,
      refunded_amount: 0
    }
  end

  def test_perfect_match
    @snapshot_client.remote_records = [@base_record]
    local_records = [@base_record]

    results = @use_case.call(local_records: local_records, run_id: "run_1")

    assert_equal 1, results.size
    assert_equal :match, results.first[:status]
    assert_equal "run_1:pi_123", results.first[:id]
    
    # Store should have the snapshot
    assert_equal 1, @store.all.size
    
    # Reporter should be empty since it's a match
    assert_empty @reporter.reports
  end

  def test_status_drift
    remote = @base_record.merge(status: "requires_payment_method")
    @snapshot_client.remote_records = [remote]
    local_records = [@base_record]

    results = @use_case.call(local_records: local_records, run_id: "run_2")
    
    assert_equal :status_drift, results.first[:status]
    assert_equal 1, @reporter.reports.size
  end

  def test_amount_drift
    remote = @base_record.merge(amount: 500)
    @snapshot_client.remote_records = [remote]
    local_records = [@base_record]

    results = @use_case.call(local_records: local_records, run_id: "run_3")
    
    assert_equal :amount_drift, results.first[:status]
  end

  def test_missing_local
    @snapshot_client.remote_records = [@base_record]
    local_records = []

    results = @use_case.call(local_records: local_records, run_id: "run_4")
    
    assert_equal :missing_local, results.first[:status]
  end

  def test_missing_remote
    @snapshot_client.remote_records = []
    local_records = [@base_record]

    results = @use_case.call(local_records: local_records, run_id: "run_5")
    
    assert_equal :missing_remote, results.first[:status]
  end

  def test_idempotent_runs
    @snapshot_client.remote_records = [@base_record]
    local_records = [@base_record]

    @use_case.call(local_records: local_records, run_id: "run_6")
    @use_case.call(local_records: local_records, run_id: "run_6")

    # Due to deterministic id run_6:pi_123, save should just overwrite the same entry
    assert_equal 1, @store.all.size
  end

  def test_immutability
    local = @base_record.dup
    remote = @base_record.merge(status: "failed")
    @snapshot_client.remote_records = [remote]

    @use_case.call(local_records: [local], run_id: "run_7")

    # Original arrays and hashes should not be mutated
    assert_equal "succeeded", local[:status]
  end
end
