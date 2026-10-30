# frozen_string_literal: true

require "test_helper"
require "payment/sdk/shared/domain/value_objects/idempotency_key"

class SharedDomainValueObjectsIdempotencyKeyTest < Minitest::Test
  def test_generation_of_uuid_when_no_argument
    key = Payment::SDK::Shared::Domain::ValueObjects::IdempotencyKey.new
    refute_nil key.value
    assert_equal 36, key.value.length
    assert_match(/\A[0-9a-f-]{36}\z/, key.value)
  end

  def test_normalization_and_to_s
    key = Payment::SDK::Shared::Domain::ValueObjects::IdempotencyKey.new("  custom-key-123  ")
    assert_equal "custom-key-123", key.value
    assert_equal "custom-key-123", key.to_s
  end

  def test_validation_rejects_empty_string
    assert_raises(ArgumentError) { Payment::SDK::Shared::Domain::ValueObjects::IdempotencyKey.new("") }
    assert_raises(ArgumentError) { Payment::SDK::Shared::Domain::ValueObjects::IdempotencyKey.new("   ") }
  end

  def test_equality_and_hash
    k1 = Payment::SDK::Shared::Domain::ValueObjects::IdempotencyKey.new("key-a")
    k2 = Payment::SDK::Shared::Domain::ValueObjects::IdempotencyKey.new("key-a")
    k3 = Payment::SDK::Shared::Domain::ValueObjects::IdempotencyKey.new("key-b")

    assert_equal k1, k2
    assert_equal k1.hash, k2.hash
    refute_equal k1, k3
  end
end
