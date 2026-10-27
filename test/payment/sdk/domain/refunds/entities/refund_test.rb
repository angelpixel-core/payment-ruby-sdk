# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/refunds/entities/refund"

class DomainRefundsEntitiesRefundTest < Minitest::Test
  def test_refund_initialization_and_helpers
    refund = Payment::SDK::Domain::Refunds::Entities::Refund.new(
      id: "re_123",
      charge_id: "ch_123",
      amount: 500,
      status: "succeeded",
      reason: "requested_by_customer",
      created_at: "2026-10-27T00:00:00Z"
    )

    assert_equal "re_123", refund.id
    assert_equal "ch_123", refund.charge_id
    assert_equal 500, refund.amount
    assert_equal "succeeded", refund.status
    assert_equal "requested_by_customer", refund.reason
    assert_equal "2026-10-27T00:00:00Z", refund.created_at
    assert refund.succeeded?
    refute refund.failed?
    refute refund.pending?
    refute refund.canceled?
    assert refund.frozen?
  end

  def test_other_statuses
    failed_refund = Payment::SDK::Domain::Refunds::Entities::Refund.new(
      id: "re_2", charge_id: "ch_1", amount: 200, status: "failed", created_at: "now"
    )
    assert failed_refund.failed?

    pending_refund = Payment::SDK::Domain::Refunds::Entities::Refund.new(
      id: "re_3", charge_id: "ch_1", amount: 200, status: "pending", created_at: "now"
    )
    assert pending_refund.pending?

    canceled_refund = Payment::SDK::Domain::Refunds::Entities::Refund.new(
      id: "re_4", charge_id: "ch_1", amount: 200, status: "canceled", created_at: "now"
    )
    assert canceled_refund.canceled?
  end
end
