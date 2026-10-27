# frozen_string_literal: true

require "test_helper"
require "payment/sdk/interfaces/webhooks/client"

class InterfacesWebhooksClientTest < Minitest::Test
  class TestProjection
    attr_reader :applied

    def initialize
      @applied = false
    end

    def apply!(inbox_entry:)
      @applied = true
    end
  end

  class TestVerifier
    def verify(payload:, signature:, secret:, timestamp_tolerance: 300)
      true
    end
  end

  def setup
    @verifier = TestVerifier.new
    @client = Payment::SDK::Interfaces::Webhooks::Client.new(
      secret: "whsec_test",
      verifier: @verifier
    )
  end

  def test_process_webhook
    projection = TestProjection.new
    result = @client.process(
      payload: { delivery_id: "del_abc", event: "test" },
      signature_header: "t=123,v1=sig",
      projection: projection
    )

    assert_equal :processed, result[:status]
    assert projection.applied
  end

  def test_parse_event
    raw = {
      delivery_id: "del_1",
      event_id: "evt_1",
      event_type: "payment_intent.succeeded",
      data: { "payment_intent_id" => "pi_1" }
    }
    event = @client.parse_event(raw)

    assert_equal "del_1", event.delivery_id
    assert_equal "evt_1", event.event_id
    assert_equal "pi_1", event.payment_intent_id
  end
end
