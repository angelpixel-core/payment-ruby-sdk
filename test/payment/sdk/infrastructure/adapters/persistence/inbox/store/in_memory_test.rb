# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/persistence/inbox/store/in_memory"

class InfrastructureAdaptersPersistenceInboxStoreInMemoryTest < Minitest::Test
  def setup
    @store = Payment::SDK::Infrastructure::Adapters::Persistence::Inbox::Store::InMemory.new
  end

  def test_persist_and_find
    entry = { delivery_id: "del_1", raw_payload: "{}", status: :received }
    persisted = @store.persist(entry)

    assert_equal "del_1", persisted[:delivery_id]
    assert_equal :received, persisted[:status]

    found = @store.find_by_delivery_id("del_1")
    assert_equal "del_1", found[:delivery_id]
  end

  def test_duplicate_delivery_id_raises_error
    entry = { delivery_id: "del_1", raw_payload: "{}", status: :received }
    @store.persist(entry)

    assert_raises(ArgumentError) { @store.persist(entry) }
  end

  def test_update_entry
    entry = { delivery_id: "del_1", raw_payload: "{}", status: :received }
    @store.persist(entry)

    updated = @store.update("del_1", status: :processed)
    assert_equal :processed, updated[:status]
    assert_equal :processed, @store.find_by_delivery_id("del_1")[:status]
  end

  def test_save_and_update_status
    entry = { delivery_id: "del_2", raw_payload: "{}", status: :received }
    @store.save(entry)

    @store.update_status(delivery_id: "del_2", status: :failed, failure_reason: "err")
    found = @store.find_by_delivery_id("del_2")
    assert_equal :failed, found[:status]
    assert_equal "err", found[:failure_reason]
  end
end
