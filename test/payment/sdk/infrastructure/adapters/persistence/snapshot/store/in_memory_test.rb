# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/persistence/snapshot/store/in_memory"

class InfrastructureAdaptersPersistenceSnapshotStoreInMemoryTest < Minitest::Test
  def setup
    @store = Payment::SDK::Infrastructure::Adapters::Persistence::Snapshot::Store::InMemory.new
  end

  def test_save_and_find_snapshot
    snapshot = {id: "run_1:pi_123", status: :match, amount: 1000}
    saved = @store.save(snapshot)

    assert_equal "run_1:pi_123", saved[:id]
    found = @store.find("run_1:pi_123")
    assert_equal :match, found[:status]
  end

  def test_find_non_existent_returns_nil
    assert_nil @store.find("non_existent")
  end

  def test_all_returns_all_snapshots
    @store.save({id: "snap_1", status: :match})
    @store.save({id: "snap_2", status: :status_drift})

    all_entries = @store.all
    assert_equal 2, all_entries.size
    assert_equal ["snap_1", "snap_2"], all_entries.map { |e| e[:id] }.sort
  end

  def test_save_overwrites_existing_entry
    @store.save({id: "snap_1", status: :status_drift})
    @store.save({id: "snap_1", status: :match})

    assert_equal 1, @store.all.size
    assert_equal :match, @store.find("snap_1")[:status]
  end

  def test_dup_isolation
    original = {id: "snap_1", status: :match}
    @store.save(original)

    original[:status] = :drift
    assert_equal :match, @store.find("snap_1")[:status]
  end

  def test_clear_empties_store
    @store.save({id: "snap_1", status: :match})
    @store.clear!

    assert_empty @store.all
    assert_nil @store.find("snap_1")
  end

  def test_thread_safety
    threads = 10.times.map do |i|
      Thread.new do
        @store.save({id: "snap_#{i}", index: i})
      end
    end
    threads.each(&:join)

    assert_equal 10, @store.all.size
  end
end
