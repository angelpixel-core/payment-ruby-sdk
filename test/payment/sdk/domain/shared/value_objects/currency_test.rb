# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/value_objects/currency"

class SharedCurrencyTest < Minitest::Test
  def test_currency_normalization
    currency = Payment::SDK::Domain::Shared::ValueObjects::Currency.new(" USD ")
    assert_equal "usd", currency.code
    assert_equal "usd", currency.to_s
  end

  def test_currency_validation
    assert_raises(ArgumentError) { Payment::SDK::Domain::Shared::ValueObjects::Currency.new("") }
    assert_raises(ArgumentError) { Payment::SDK::Domain::Shared::ValueObjects::Currency.new(nil) }
    assert_raises(ArgumentError) { Payment::SDK::Domain::Shared::ValueObjects::Currency.new("us") }
    assert_raises(ArgumentError) { Payment::SDK::Domain::Shared::ValueObjects::Currency.new("usdd") }
  end

  def test_currency_equality
    curr1 = Payment::SDK::Domain::Shared::ValueObjects::Currency.new("USD")
    curr2 = Payment::SDK::Domain::Shared::ValueObjects::Currency.new("usd")
    assert_equal curr1, curr2
    assert curr1.eql?(curr2)
    assert_equal curr1.hash, curr2.hash
  end
end
