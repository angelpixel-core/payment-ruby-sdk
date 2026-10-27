# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/payments/entities/charge"

class DomainChargeTest < Minitest::Test
  def test_charge_capture_states
    charge = Payment::SDK::Domain::Payments::Entities::Charge.new(
      id: "ch_123",
      payment_intent_id: "pi_123",
      amount: 1000,
      captured_amount: 500,
      status: "succeeded"
    )

    assert_equal "ch_123", charge.id
    assert charge.succeeded?
    assert charge.partially_captured?
    refute charge.fully_captured?
    refute charge.uncaptured?
    assert charge.frozen?
  end

  def test_charge_fully_captured_and_refunded
    charge = Payment::SDK::Domain::Payments::Entities::Charge.new(
      id: "ch_456",
      payment_intent_id: "pi_456",
      amount: 1000,
      captured_amount: 1000,
      refunded_amount: 1000,
      status: "succeeded"
    )

    assert charge.fully_captured?
    assert charge.fully_refunded?
  end
end
