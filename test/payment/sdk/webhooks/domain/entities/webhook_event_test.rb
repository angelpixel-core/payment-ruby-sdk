# frozen_string_literal: true

require "test_helper"
require "payment/sdk/webhooks/domain/entities/webhook_event"

class WebhooksDomainEntitiesWebhookEventTest < Minitest::Test
  def test_initialization_with_data_define
    event = Payment::SDK::Webhooks::Domain::Entities::WebhookEvent.new(
      delivery_id: "del_1",
      event_id: "evt_1",
      event_type: "payment_intent.succeeded",
      created_at: "2024-01-01T00:00:00Z",
      data: { object: { id: "pi_123" } },
      raw_payload: "{}"
    )

    assert_equal "del_1", event.delivery_id
    assert_equal "evt_1", event.event_id
    assert_equal "payment_intent.succeeded", event.event_type
    assert_equal "pi_123", event.payment_intent_id
    assert event.frozen?
    assert_kind_of Data, event
    assert_kind_of Payment::SDK::Shared::Domain::Concerns::PayloadExtractable, event
    assert_equal "Payment::SDK::Webhooks::Domain::Entities::WebhookEvent", Payment::SDK::Webhooks::Domain::Entities::WebhookEvent.name
  end

  def test_charge_and_refund_id_extraction
    charge_event = Payment::SDK::Webhooks::Domain::Entities::WebhookEvent.new(
      delivery_id: "del_2",
      event_id: "evt_2",
      event_type: "charge.succeeded",
      created_at: nil,
      data: { object: { id: "ch_123" } },
      raw_payload: "{}"
    )
    assert_equal "ch_123", charge_event.charge_id

    refund_event = Payment::SDK::Webhooks::Domain::Entities::WebhookEvent.new(
      delivery_id: "del_3",
      event_id: "evt_3",
      event_type: "refund.succeeded",
      created_at: nil,
      data: { object: { id: "re_123" } },
      raw_payload: "{}"
    )
    assert_equal "re_123", refund_event.refund_id
  end
end
