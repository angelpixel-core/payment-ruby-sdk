# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/persistence/snapshot/store/active_record"

class InfrastructureAdaptersPersistenceSnapshotStoreActiveRecordTest < Minitest::Test
  class FakeActiveRecordModel
    class << self
      attr_reader :records

      def reset!
        @records = {}
      end

      def find_or_initialize_by(snapshot_id: nil, id: nil)
        lookup_id = snapshot_id || id
        @records[lookup_id] ||= new(id: lookup_id, snapshot_id: snapshot_id)
      end

      def find_by(snapshot_id: nil, id: nil)
        lookup_id = snapshot_id || id
        @records[lookup_id]
      end

      def all
        @records.values
      end

      def delete_all
        @records.clear
      end
    end

    attr_accessor :id, :snapshot_id, :run_id, :payment_intent_id, :status, :local_data, :remote_data, :reconciled_at

    def initialize(attrs = {})
      attrs.each do |k, v|
        public_send(:"#{k}=", v) if respond_to?(:"#{k}=")
      end
    end

    def save!
      self.class.records[snapshot_id || id] = self
      true
    end
  end

  def setup
    FakeActiveRecordModel.reset!
    @store = Payment::SDK::Infrastructure::Adapters::Persistence::Snapshot::Store::ActiveRecord.new(
      model_class: FakeActiveRecordModel
    )
  end

  def test_saves_new_snapshot_record
    snapshot = {
      id: "run_1:pi_100",
      run_id: "run_1",
      payment_intent_id: "pi_100",
      status: :matched,
      local_data: {amount: 1000},
      remote_data: {amount: 1000},
      reconciled_at: Time.utc(2026, 10, 29, 12, 0, 0)
    }

    result = @store.save(snapshot)

    assert_equal "run_1:pi_100", result[:id]
    assert_equal "run_1", result[:run_id]
    assert_equal "pi_100", result[:payment_intent_id]
    assert_equal :matched, result[:status]
    assert_equal({amount: 1000}, result[:local_data])
  end

  def test_find_snapshot_by_id
    snapshot = {
      id: "run_2:pi_200",
      run_id: "run_2",
      payment_intent_id: "pi_200",
      status: :missing_in_remote
    }
    @store.save(snapshot)

    found = @store.find("run_2:pi_200")
    refute_nil found
    assert_equal "run_2:pi_200", found[:id]
    assert_equal :missing_in_remote, found[:status]

    assert_nil @store.find("non_existent")
  end

  def test_all_returns_all_persisted_snapshots
    @store.save(id: "run_3:pi_1", run_id: "run_3", payment_intent_id: "pi_1", status: :matched)
    @store.save(id: "run_3:pi_2", run_id: "run_3", payment_intent_id: "pi_2", status: :drift_amount)

    all_snapshots = @store.all
    assert_equal 2, all_snapshots.size
    ids = all_snapshots.map { |s| s[:id] }
    assert_includes ids, "run_3:pi_1"
    assert_includes ids, "run_3:pi_2"
  end

  def test_clear_removes_all_records
    @store.save(id: "run_4:pi_1", run_id: "run_4", payment_intent_id: "pi_1", status: :matched)
    assert_equal 1, @store.all.size

    @store.clear!
    assert_empty @store.all
  end
end
