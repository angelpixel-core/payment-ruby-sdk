# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/value_objects/money"

class SharedMoneyTest < Minitest::Test
  def test_money_initialization
    money = Payment::SDK::Domain::Shared::ValueObjects::Money.new(1000, "usd")
    assert_equal 1000, money.amount
    assert_equal "usd", money.currency.code
  end

  def test_money_validation
    assert_raises(ArgumentError) { Payment::SDK::Domain::Shared::ValueObjects::Money.new(10.5, "usd") }
    assert_raises(ArgumentError) { Payment::SDK::Domain::Shared::ValueObjects::Money.new("1000", "usd") }
  end

  def test_money_arithmetic
    m1 = Payment::SDK::Domain::Shared::ValueObjects::Money.new(1000, "usd")
    m2 = Payment::SDK::Domain::Shared::ValueObjects::Money.new(500, "usd")

    assert_equal Payment::SDK::Domain::Shared::ValueObjects::Money.new(1500, "usd"), m1 + m2
    assert_equal Payment::SDK::Domain::Shared::ValueObjects::Money.new(500, "usd"), m1 - m2
  end

  def test_money_arithmetic_currency_mismatch
    m1 = Payment::SDK::Domain::Shared::ValueObjects::Money.new(1000, "usd")
    m2 = Payment::SDK::Domain::Shared::ValueObjects::Money.new(500, "eur")

    assert_raises(ArgumentError) { m1 + m2 }
    assert_raises(ArgumentError) { m1 - m2 }
  end

  def test_money_comparison
    m1 = Payment::SDK::Domain::Shared::ValueObjects::Money.new(1000, "usd")
    m2 = Payment::SDK::Domain::Shared::ValueObjects::Money.new(500, "usd")
    m3 = Payment::SDK::Domain::Shared::ValueObjects::Money.new(1000, "usd")

    assert m1 > m2
    assert m2 < m1
    assert m1 == m3
    assert m1.eql?(m3)
    assert_equal m1.hash, m3.hash
  end
end
