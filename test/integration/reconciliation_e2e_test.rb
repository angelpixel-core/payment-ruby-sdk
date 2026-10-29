# frozen_string_literal: true

require "integration_helper"
require "securerandom"

class ReconciliationE2ETest < Payment::IntegrationTest
  def test_reconciliation_against_live_sandbox
    # 1. Create and confirm an intent so transactions exist in the sandbox
    idem_create = "e2e_rec_create_#{SecureRandom.hex(6)}"
    create_res = client.create_payment_intent(
      amount: 9900,
      currency: "usd",
      capture_method: "automatic",
      idempotency_key: idem_create
    )
    intent = create_res[:payment_intent] || create_res
    intent_id = intent[:id]

    idem_confirm = "e2e_rec_confirm_#{SecureRandom.hex(6)}"
    confirm_res = client.confirm_payment_intent(
      intent_id,
      payment_method_token: "pm_card_visa",
      idempotency_key: idem_confirm
    )
    attempt_id = confirm_res.dig(:payment_attempt, :id) || confirm_res.dig("payment_attempt", "id")

    # 2. Query transaction report and snapshot endpoints
    report = client.get_transaction_report
    refute_nil report

    snapshot_data = client.get_transaction_snapshot
    refute_nil snapshot_data

    # 3. Reconcile matching local record against the remote snapshot
    local_records = [
      {
        id: intent_id,
        status: :succeeded,
        amount: 9900,
        currency: "usd",
        latest_attempt_id: attempt_id
      }
    ]

    run_id = "e2e_run_#{SecureRandom.hex(4)}"
    results = client.reconcile(local_records: local_records, run_id: run_id)

    refute_empty results
    matching_result = results.find { |r| r[:payment_intent_id] == intent_id }
    refute_nil matching_result
    assert_equal :match, matching_result[:status]
  end
end
