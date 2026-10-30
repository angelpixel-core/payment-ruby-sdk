# frozen_string_literal: true

require "test_helper"
require "payment/sdk/refunds/domain/entities/refund"

class RefundsDomainEntitiesRefundTest < Minitest::Test
  def test_initialization_and_symbol_status
    refund = Payment::SDK::Refunds::Domain::Entities::Refund.new(
      id: "re_123",
      charge_id: "ch_123",
      amount: 500,
      status: "succeeded",
      reason: "duplicate"
    )

    assert_equal "re_123", refund.id
    assert_equal "ch_123", refund.charge_id
    assert_equal 500, refund.amount
    assert_equal :succeeded, refund.status
    assert_equal "duplicate", refund.reason
    assert refund.succeeded?
    refute refund.failed?
    assert refund.frozen?
  end

  def test_pending_predicate
    refund = Payment::SDK::Refunds::Domain::Entities::Refund.new(
      id: "re_123", charge_id: "ch_123", amount: 500, status: :pending
    )
    assert refund.pending?
  end
end
