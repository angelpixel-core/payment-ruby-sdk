# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/payments/entities/payment_intent"

class DomainPaymentIntentTest < Minitest::Test
  def test_payment_intent_initialization_and_helpers
    intent = Payment::SDK::Domain::Payments::Entities::PaymentIntent.new(
      id: "pi_123",
      amount: 1000,
      currency: "usd",
      status: "requires_capture",
      customer_id: "cus_123",
      merchant_id: "mer_123",
      capture_method: "manual"
    )

    assert_equal "pi_123", intent.id
    assert_equal 1000, intent.amount
    assert_equal "usd", intent.currency
    assert intent.requires_capture?
    refute intent.succeeded?
    refute intent.canceled?
    refute intent.requires_payment_method?
    refute intent.processing?
    assert intent.frozen?
  end

  def test_payment_intent_other_statuses
    succeeded = Payment::SDK::Domain::Payments::Entities::PaymentIntent.new(
      id: "pi_1", amount: 100, currency: "usd", status: "succeeded",
      customer_id: "c_1", merchant_id: "m_1", capture_method: "automatic"
    )
    assert succeeded.succeeded?

    canceled = Payment::SDK::Domain::Payments::Entities::PaymentIntent.new(
      id: "pi_2", amount: 100, currency: "usd", status: "canceled",
      customer_id: "c_1", merchant_id: "m_1", capture_method: "automatic"
    )
    assert canceled.canceled?
  end
end
