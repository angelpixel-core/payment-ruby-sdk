# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/domain/entities/payment_attempt"

class PaymentsDomainEntitiesPaymentAttemptTest < Minitest::Test
  def test_initialization_and_symbol_status
    attempt = Payment::SDK::Payments::Domain::Entities::PaymentAttempt.new(
      id: "pa_123",
      payment_intent_id: "pi_123",
      status: "failed",
      payment_method_type: "card",
      error_code: "insufficient_funds"
    )

    assert_equal "pa_123", attempt.id
    assert_equal :failed, attempt.status
    assert attempt.failed?
    refute attempt.succeeded?
    assert attempt.frozen?
  end

  def test_succeeded_predicate
    attempt = Payment::SDK::Payments::Domain::Entities::PaymentAttempt.new(
      id: "pa_123", payment_intent_id: "pi_123", status: "succeeded",
      payment_method_type: "card"
    )
    assert attempt.succeeded?

    legacy_attempt = Payment::SDK::Payments::Domain::Entities::PaymentAttempt.new(
      id: "pa_124", payment_intent_id: "pi_123", status: "successful",
      payment_method_type: "card"
    )
    assert legacy_attempt.succeeded?
  end
end
