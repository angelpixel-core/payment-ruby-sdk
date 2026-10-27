# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/domain/entities/payment_intent"

class PaymentsDomainEntitiesPaymentIntentTest < Minitest::Test
  def test_initialization_and_symbol_status
    intent = Payment::SDK::Payments::Domain::Entities::PaymentIntent.new(
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
    assert_equal :requires_capture, intent.status
    assert intent.requires_capture?
    refute intent.succeeded?
    refute intent.requires_payment_method?
    assert intent.frozen?
  end

  def test_succeeded_predicate
    intent = Payment::SDK::Payments::Domain::Entities::PaymentIntent.new(
      id: "pi_123", amount: 1000, currency: "usd", status: :succeeded,
      customer_id: "cus_123", merchant_id: "mer_123"
    )
    assert intent.succeeded?
  end
end
