# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/payments/entities/payment_attempt"

class DomainPaymentAttemptTest < Minitest::Test
  def test_payment_attempt_attributes
    attempt = Payment::SDK::Domain::Payments::Entities::PaymentAttempt.new(
      id: "pa_123",
      payment_intent_id: "pi_123",
      status: "failed",
      payment_method_type: "card",
      error_code: "insufficient_funds",
      created_at: "2026-10-27T00:00:00Z"
    )

    assert_equal "pa_123", attempt.id
    assert_equal "pi_123", attempt.payment_intent_id
    assert_equal "failed", attempt.status
    assert_equal "card", attempt.payment_method_type
    assert_equal "insufficient_funds", attempt.error_code
    assert attempt.failed?
    refute attempt.succeeded?
    assert attempt.frozen?
  end
end
