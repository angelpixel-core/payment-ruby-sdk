# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/entities/payment_intent"
require "payment/sdk/domain/entities/payment_attempt"
require "payment/sdk/domain/entities/charge"
require "payment/sdk/domain/entities/refund"

class EntitiesTest < Minitest::Test
  def test_payment_intent
    intent = Payment::SDK::Domain::Entities::PaymentIntent.new(
      id: "pi_123", amount: 1000, currency: "usd", status: "requires_capture",
      customer_id: "cus_123", merchant_id: "mer_123", capture_method: "manual"
    )

    assert_equal "pi_123", intent.id
    assert_equal 1000, intent.amount
    assert_equal "usd", intent.currency
    assert intent.requires_capture?
    refute intent.succeeded?
    assert intent.frozen?
  end

  def test_payment_attempt
    attempt = Payment::SDK::Domain::Entities::PaymentAttempt.new(
      id: "pa_123", payment_intent_id: "pi_123", status: "failed",
      payment_method_type: "card", error_code: "insufficient_funds", created_at: "2024-01-01"
    )

    assert_equal "pa_123", attempt.id
    assert_equal "failed", attempt.status
    assert attempt.failed?
    refute attempt.succeeded?
    assert attempt.frozen?
  end

  def test_charge
    charge = Payment::SDK::Domain::Entities::Charge.new(
      id: "ch_123", payment_intent_id: "pi_123", amount: 1000,
      captured_amount: 500, status: "succeeded"
    )

    assert_equal "ch_123", charge.id
    assert charge.succeeded?
    assert charge.partially_captured?
    refute charge.fully_captured?
    assert charge.frozen?
  end

  def test_refund
    refund = Payment::SDK::Domain::Entities::Refund.new(
      id: "re_123", charge_id: "ch_123", amount: 500, status: "succeeded",
      reason: "requested_by_customer", created_at: "2024-01-01"
    )

    assert_equal "re_123", refund.id
    assert_equal "requested_by_customer", refund.reason
    assert refund.succeeded?
    assert refund.frozen?
  end
end
