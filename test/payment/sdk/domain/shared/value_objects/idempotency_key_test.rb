# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/value_objects/idempotency_key"

class SharedIdempotencyKeyTest < Minitest::Test
  def test_idempotency_key_generation
    key = Payment::SDK::Domain::Shared::ValueObjects::IdempotencyKey.new
    refute_nil key.value
    assert_equal 36, key.value.length
    assert_equal key.value, key.to_s
  end

  def test_idempotency_key_validation
    assert_raises(ArgumentError) { Payment::SDK::Domain::Shared::ValueObjects::IdempotencyKey.new("  ") }
    assert_raises(ArgumentError) { Payment::SDK::Domain::Shared::ValueObjects::IdempotencyKey.new("") }
  end

  def test_idempotency_key_normalization
    key = Payment::SDK::Domain::Shared::ValueObjects::IdempotencyKey.new(" my-key ")
    assert_equal "my-key", key.value
  end

  def test_idempotency_key_equality
    key1 = Payment::SDK::Domain::Shared::ValueObjects::IdempotencyKey.new("key-1")
    key2 = Payment::SDK::Domain::Shared::ValueObjects::IdempotencyKey.new("key-1")
    assert_equal key1, key2
    assert key1.eql?(key2)
    assert_equal key1.hash, key2.hash
  end
end
