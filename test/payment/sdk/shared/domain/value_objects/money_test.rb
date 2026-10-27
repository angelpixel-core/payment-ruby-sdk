# frozen_string_literal: true

require "test_helper"
require "payment/sdk/shared/domain/value_objects/money"

class SharedDomainValueObjectsMoneyTest < Minitest::Test
  def test_initialization_with_cents_and_currency_string
    money = Payment::SDK::Shared::Domain::ValueObjects::Money.new(1000, "usd")
    assert_equal 1000, money.amount
    assert_equal "usd", money.currency.code
    assert_equal "1000 usd", money.to_s
  end

  def test_initialization_rejects_floats
    assert_raises(ArgumentError) { Payment::SDK::Shared::Domain::ValueObjects::Money.new(10.5, "usd") }
  end

  def test_arithmetic_addition_and_subtraction
    m1 = Payment::SDK::Shared::Domain::ValueObjects::Money.new(1000, "usd")
    m2 = Payment::SDK::Shared::Domain::ValueObjects::Money.new(500, "usd")

    sum = m1 + m2
    assert_equal 1500, sum.amount
    assert_equal "usd", sum.currency.code

    diff = m1 - m2
    assert_equal 500, diff.amount
  end

  def test_arithmetic_rejects_currency_mismatch
    m1 = Payment::SDK::Shared::Domain::ValueObjects::Money.new(1000, "usd")
    m2 = Payment::SDK::Shared::Domain::ValueObjects::Money.new(500, "eur")

    assert_raises(ArgumentError) { m1 + m2 }
    assert_raises(ArgumentError) { m1 - m2 }
    assert_raises(ArgumentError) { m1 <=> m2 }
  end

  def test_comparable_and_equality
    m1 = Payment::SDK::Shared::Domain::ValueObjects::Money.new(1000, "usd")
    m2 = Payment::SDK::Shared::Domain::ValueObjects::Money.new(500, "usd")
    m3 = Payment::SDK::Shared::Domain::ValueObjects::Money.new(1000, "usd")

    assert m1 > m2
    assert m2 < m1
    assert_equal m1, m3
    assert_equal m1.hash, m3.hash
  end
end
