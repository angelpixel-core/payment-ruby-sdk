# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/value_objects/currency"
require "payment/sdk/domain/value_objects/money"
require "payment/sdk/domain/value_objects/idempotency_key"

class ValueObjectsTest < Minitest::Test
  def test_currency_normalization
    currency = Payment::SDK::Domain::ValueObjects::Currency.new(" USD ")
    assert_equal "usd", currency.code
  end

  def test_currency_validation
    assert_raises(ArgumentError) { Payment::SDK::Domain::ValueObjects::Currency.new("") }
    assert_raises(ArgumentError) { Payment::SDK::Domain::ValueObjects::Currency.new("us") }
    assert_raises(ArgumentError) { Payment::SDK::Domain::ValueObjects::Currency.new("usdd") }
  end

  def test_currency_equality
    curr1 = Payment::SDK::Domain::ValueObjects::Currency.new("USD")
    curr2 = Payment::SDK::Domain::ValueObjects::Currency.new("usd")
    assert_equal curr1, curr2
  end

  def test_money_initialization
    money = Payment::SDK::Domain::ValueObjects::Money.new(1000, "usd")
    assert_equal 1000, money.amount
    assert_equal "usd", money.currency.code
  end

  def test_money_validation
    assert_raises(ArgumentError) { Payment::SDK::Domain::ValueObjects::Money.new(10.5, "usd") }
  end

  def test_money_arithmetic
    m1 = Payment::SDK::Domain::ValueObjects::Money.new(1000, "usd")
    m2 = Payment::SDK::Domain::ValueObjects::Money.new(500, "usd")
    
    assert_equal Payment::SDK::Domain::ValueObjects::Money.new(1500, "usd"), m1 + m2
    assert_equal Payment::SDK::Domain::ValueObjects::Money.new(500, "usd"), m1 - m2
  end

  def test_money_arithmetic_currency_mismatch
    m1 = Payment::SDK::Domain::ValueObjects::Money.new(1000, "usd")
    m2 = Payment::SDK::Domain::ValueObjects::Money.new(500, "eur")
    
    assert_raises(ArgumentError) { m1 + m2 }
  end

  def test_money_comparison
    m1 = Payment::SDK::Domain::ValueObjects::Money.new(1000, "usd")
    m2 = Payment::SDK::Domain::ValueObjects::Money.new(500, "usd")
    m3 = Payment::SDK::Domain::ValueObjects::Money.new(1000, "usd")
    
    assert m1 > m2
    assert m1 == m3
  end

  def test_idempotency_key_generation
    key = Payment::SDK::Domain::ValueObjects::IdempotencyKey.new
    refute_nil key.value
    assert_equal 36, key.value.length # UUID length
  end

  def test_idempotency_key_validation
    assert_raises(ArgumentError) { Payment::SDK::Domain::ValueObjects::IdempotencyKey.new("  ") }
  end

  def test_idempotency_key_normalization
    key = Payment::SDK::Domain::ValueObjects::IdempotencyKey.new(" my-key ")
    assert_equal "my-key", key.value
  end

  def test_idempotency_key_equality
    key1 = Payment::SDK::Domain::ValueObjects::IdempotencyKey.new("key-1")
    key2 = Payment::SDK::Domain::ValueObjects::IdempotencyKey.new("key-1")
    assert_equal key1, key2
  end
end
