# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/domain/entities/charge"

class PaymentsDomainEntitiesChargeTest < Minitest::Test
  def test_initialization_and_symbol_status
    charge = Payment::SDK::Payments::Domain::Entities::Charge.new(
      id: "ch_123",
      payment_intent_id: "pi_123",
      amount: 1000,
      captured_amount: 500,
      status: "succeeded"
    )

    assert_equal "ch_123", charge.id
    assert_equal 1000, charge.amount
    assert_equal 500, charge.captured_amount
    assert_equal :succeeded, charge.status
    assert charge.succeeded?
    assert charge.partially_captured?
    refute charge.fully_captured?
    assert charge.frozen?
  end

  def test_fully_captured_predicate
    charge = Payment::SDK::Payments::Domain::Entities::Charge.new(
      id: "ch_123", payment_intent_id: "pi_123", amount: 1000,
      captured_amount: 1000, status: :succeeded
    )
    assert charge.fully_captured?
    refute charge.partially_captured?
  end
end
