# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/webhooks/entities/webhook_event"

class DomainWebhooksEntitiesWebhookEventTest < Minitest::Test
  def test_webhook_event_with_data_define
    event = Payment::SDK::Domain::Webhooks::Entities::WebhookEvent.new(
      delivery_id: "del_123",
      event_id: "evt_123",
      event_type: "payment_intent.succeeded",
      data: { "payment_intent_id" => "pi_123" },
      created_at: "2026-10-27T00:00:00Z"
    )

    assert_equal "del_123", event.delivery_id
    assert_equal "evt_123", event.event_id
    assert_equal "payment_intent.succeeded", event.event_type
    assert_equal "pi_123", event.payment_intent_id
    assert_nil event.charge_id
    assert event.frozen?

    # Verify Data equality by value
    same_event = Payment::SDK::Domain::Webhooks::Entities::WebhookEvent.new(
      delivery_id: "del_123",
      event_id: "evt_123",
      event_type: "payment_intent.succeeded",
      data: { "payment_intent_id" => "pi_123" },
      created_at: "2026-10-27T00:00:00Z"
    )
    assert_equal event, same_event
  end

  def test_charge_event_dig_data
    event = Payment::SDK::Domain::Webhooks::Entities::WebhookEvent.new(
      delivery_id: "del_456",
      event_id: "evt_456",
      event_type: "charge.succeeded",
      data: { object: { id: "ch_456" } },
      created_at: "2026-10-27T00:00:00Z"
    )

    assert_equal "ch_456", event.charge_id
    assert_nil event.payment_intent_id
  end
end
