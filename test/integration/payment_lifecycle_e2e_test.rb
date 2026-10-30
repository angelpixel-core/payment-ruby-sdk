# frozen_string_literal: true

require "integration_helper"
require "securerandom"

class PaymentLifecycleE2ETest < Payment::IntegrationTest
  def test_automatic_capture_payment_lifecycle
    idem_create = "e2e_auto_create_#{SecureRandom.hex(6)}"
    create_res = client.create_payment_intent(
      amount: 5000,
      currency: "usd",
      capture_method: "automatic",
      idempotency_key: idem_create
    )

    intent = create_res[:payment_intent] || create_res
    refute_nil intent[:id]
    assert_equal 5000, intent[:amount]
    assert_includes %w[USD usd], intent[:currency]
    assert_equal "requires_payment_method", intent[:status]

    idem_confirm = "e2e_auto_confirm_#{SecureRandom.hex(6)}"
    confirm_res = client.confirm_payment_intent(
      intent[:id],
      payment_method_token: "pm_card_visa",
      idempotency_key: idem_confirm
    )

    confirmed_intent = confirm_res[:payment_intent] || confirm_res
    assert_equal intent[:id], confirmed_intent[:id]
    assert_equal "succeeded", confirmed_intent[:status]

    # Inspection of charge and attempt
    charge = confirm_res[:charge]
    refute_nil charge
    assert_equal intent[:id], charge[:payment_intent_id]

    attempt = confirm_res[:payment_attempt]
    refute_nil attempt

    # Query payment intent by ID
    get_res = client.get_payment_intent(intent[:id])
    fetched_intent = get_res[:payment_intent] || get_res
    assert_equal "succeeded", fetched_intent[:status]

    # Query charge by ID
    charge_res = client.payments.charges.get(charge[:id])
    fetched_charge = charge_res[:charge] || charge_res
    assert_equal charge[:id], fetched_charge[:id]

    # Query attempt by ID
    attempt_res = client.payments.attempts.get(attempt[:id])
    fetched_attempt = attempt_res[:payment_attempt] || attempt_res
    assert_equal attempt[:id], fetched_attempt[:id]

    # Query lifecycle
    lifecycle_res = client.get_payment_lifecycle(intent[:id])
    refute_nil lifecycle_res
  end

  def test_manual_capture_payment_lifecycle
    idem_create = "e2e_manual_create_#{SecureRandom.hex(6)}"
    create_res = client.create_payment_intent(
      amount: 8000,
      currency: "usd",
      capture_method: "manual",
      idempotency_key: idem_create
    )

    intent = create_res[:payment_intent] || create_res
    assert_equal "requires_payment_method", intent[:status]

    idem_confirm = "e2e_manual_confirm_#{SecureRandom.hex(6)}"
    confirm_res = client.confirm_payment_intent(
      intent[:id],
      payment_method_token: "pm_card_visa",
      idempotency_key: idem_confirm
    )

    confirmed_intent = confirm_res[:payment_intent] || confirm_res
    assert_equal "requires_capture", confirmed_intent[:status]

    idem_capture = "e2e_manual_capture_#{SecureRandom.hex(6)}"
    capture_res = client.capture_payment_intent(
      intent[:id],
      amount: 4000,
      idempotency_key: idem_capture
    )

    captured_intent = capture_res[:payment_intent] || capture_res
    assert_equal "succeeded", captured_intent[:status]

    charge = capture_res[:charge]
    refute_nil charge
    assert_equal 4000, charge[:captured_amount]
  end

  def test_refund_lifecycle
    idem_create = "e2e_ref_create_#{SecureRandom.hex(6)}"
    create_res = client.create_payment_intent(
      amount: 6000,
      currency: "usd",
      capture_method: "automatic",
      idempotency_key: idem_create
    )

    intent = create_res[:payment_intent] || create_res

    idem_confirm = "e2e_ref_confirm_#{SecureRandom.hex(6)}"
    confirm_res = client.confirm_payment_intent(
      intent[:id],
      payment_method_token: "pm_card_visa",
      idempotency_key: idem_confirm
    )

    charge = confirm_res[:charge]
    refute_nil charge

    idem_refund = "e2e_ref_refund_#{SecureRandom.hex(6)}"
    refund_res = client.create_refund(
      charge_id: charge[:id],
      amount: 3000,
      reason: "requested_by_customer",
      idempotency_key: idem_refund
    )

    refund = refund_res[:refund] || refund_res
    refute_nil refund[:id]
    assert_equal 3000, refund[:amount]

    get_refund_res = client.get_refund(refund[:id])
    fetched_refund = get_refund_res[:refund] || get_refund_res
    assert_equal refund[:id], fetched_refund[:id]
  end
end
