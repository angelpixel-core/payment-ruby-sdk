# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/webhooks/event_parser"

class EventParserTest < Minitest::Test
  def test_parse_valid_json_string
    payload = <<~JSON
      {
        "delivery_id": "del_123",
        "event_id": "evt_123",
        "event_type": "payment_intent.succeeded",
        "created_at": "2024-01-01T00:00:00Z",
        "data": {
          "object": {
            "id": "pi_123"
          }
        }
      }
    JSON

    event = Payment::SDK::Infrastructure::Webhooks::EventParser.parse(payload)
    
    assert_equal "del_123", event.delivery_id
    assert_equal "evt_123", event.event_id
    assert_equal "payment_intent.succeeded", event.event_type
    assert_equal "pi_123", event.payment_intent_id
  end

  def test_parse_valid_hash
    payload = {
      delivery_id: "del_123",
      id: "evt_123", # Can use 'id' instead of 'event_id'
      type: "charge.succeeded", # Can use 'type' instead of 'event_type'
      data: {
        charge_id: "ch_123"
      }
    }

    event = Payment::SDK::Infrastructure::Webhooks::EventParser.parse(payload)
    
    assert_equal "del_123", event.delivery_id
    assert_equal "evt_123", event.event_id
    assert_equal "charge.succeeded", event.event_type
    assert_equal "ch_123", event.charge_id
  end

  def test_parse_missing_required_fields
    assert_raises(Payment::SDK::InvalidRequestError) do
      Payment::SDK::Infrastructure::Webhooks::EventParser.parse({ event_id: "evt_123", event_type: "type" })
    end

    assert_raises(Payment::SDK::InvalidRequestError) do
      Payment::SDK::Infrastructure::Webhooks::EventParser.parse({ delivery_id: "del_123", event_type: "type" })
    end

    assert_raises(Payment::SDK::InvalidRequestError) do
      Payment::SDK::Infrastructure::Webhooks::EventParser.parse({ delivery_id: "del_123", event_id: "evt_123" })
    end
  end

  def test_parse_invalid_json
    assert_raises(Payment::SDK::InvalidRequestError) do
      Payment::SDK::Infrastructure::Webhooks::EventParser.parse("{ invalid_json }")
    end
  end
end
