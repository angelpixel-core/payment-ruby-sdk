# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/persistence/inbox/store/redis"

class InfrastructureAdaptersPersistenceInboxStoreRedisTest < Minitest::Test
  class FakeRedis
    attr_reader :store, :ttls

    def initialize
      @store = {}
      @ttls = {}
    end

    def get(key)
      @store[key]
    end

    def set(key, value, nx: false, ex: nil)
      if nx && @store.key?(key)
        return nil
      end

      @store[key] = value
      @ttls[key] = ex if ex
      true
    end

    def del(key)
      @ttls.delete(key)
      @store.delete(key) ? 1 : 0
    end
  end

  def setup
    @fake_redis = FakeRedis.new
    @store = Payment::SDK::Infrastructure::Adapters::Persistence::Inbox::Store::Redis.new(
      redis: @fake_redis,
      prefix: "test:inbox:",
      ttl: 3600
    )
  end

  def test_saves_new_entry_and_sets_ttl
    entry = {
      delivery_id: "del_123",
      payload: '{"event":"payment_intent.succeeded"}',
      status: :pending,
      created_at: "2026-10-29T10:00:00Z"
    }

    result = @store.save(entry)

    assert_equal "del_123", result[:delivery_id]
    assert_equal :pending, result[:status]

    redis_raw = @fake_redis.get("test:inbox:del_123")
    refute_nil redis_raw
    assert_equal 3600, @fake_redis.ttls["test:inbox:del_123"]
  end

  def test_duplicate_delivery_id_raises_argument_error
    entry = {
      delivery_id: "del_dup",
      status: :pending
    }

    @store.save(entry)

    assert_raises(ArgumentError) do
      @store.save(entry)
    end
  end

  def test_missing_delivery_id_raises_argument_error
    assert_raises(ArgumentError) do
      @store.save({status: :pending})
    end
  end

  def test_find_by_delivery_id
    entry = {
      delivery_id: "del_find",
      status: :validated
    }
    @store.save(entry)

    found = @store.find_by_delivery_id("del_find")
    assert_equal "del_find", found[:delivery_id]
    assert_equal :validated, found[:status]

    assert_nil @store.find_by_delivery_id("non_existent")
  end

  def test_update_merges_attributes
    entry = {
      delivery_id: "del_upd",
      status: :pending
    }
    @store.save(entry)

    updated = @store.update("del_upd", {status: :processed, processed_at: "2026-10-29T11:00:00Z"})
    assert_equal :processed, updated[:status]
    assert_equal "2026-10-29T11:00:00Z", updated[:processed_at]

    assert_nil @store.update("unknown", {status: :failed})
  end

  def test_update_status_helper
    entry = {
      delivery_id: "del_status",
      status: :pending
    }
    @store.save(entry)

    updated = @store.update_status(
      delivery_id: "del_status",
      status: :failed,
      failure_reason: "Signature mismatch"
    )

    assert_equal :failed, updated[:status]
    assert_equal "Signature mismatch", updated[:failure_reason]
  end

  def test_delete_removes_entry
    entry = {delivery_id: "del_del", status: :pending}
    @store.save(entry)

    assert @store.delete("del_del")
    assert_nil @store.find_by_delivery_id("del_del")
    refute @store.delete("del_del")
  end
end
