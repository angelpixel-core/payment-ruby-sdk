# frozen_string_literal: true

require "test_helper"
require "payment/sdk/shared/domain/value_objects/currency"

class SharedDomainValueObjectsCurrencyTest < Minitest::Test
  def test_normalization_to_lowercase
    curr = Payment::SDK::Shared::Domain::ValueObjects::Currency.new(" USD ")
    assert_equal "usd", curr.code
    assert_equal "usd", curr.to_s
  end

  def test_validation_rejects_empty_and_invalid
    assert_raises(ArgumentError) { Payment::SDK::Shared::Domain::ValueObjects::Currency.new("") }
    assert_raises(ArgumentError) { Payment::SDK::Shared::Domain::ValueObjects::Currency.new("us") }
    assert_raises(ArgumentError) { Payment::SDK::Shared::Domain::ValueObjects::Currency.new("usdd") }
    assert_raises(ArgumentError) { Payment::SDK::Shared::Domain::ValueObjects::Currency.new("123") }
  end

  def test_equality_and_hash
    c1 = Payment::SDK::Shared::Domain::ValueObjects::Currency.new("USD")
    c2 = Payment::SDK::Shared::Domain::ValueObjects::Currency.new("usd")
    c3 = Payment::SDK::Shared::Domain::ValueObjects::Currency.new("EUR")

    assert_equal c1, c2
    assert_equal c1.hash, c2.hash
    refute_equal c1, c3
  end
end
