# frozen_string_literal: true

require "test_helper"
require "payment/sdk/webhooks/interfaces/client"

class WebhooksInterfacesClientTest < Minitest::Test
  class DummyProjection
    attr_reader :called
    def apply!(inbox_entry:)
      @called = true
    end
  end

  class MockVerifier
    def verify(payload:, signature:, secret:, timestamp_tolerance: 300)
      true
    end
  end

  def setup
    @client = Payment::SDK::Webhooks::Interfaces::Client.new(
      secret: "whsec_test",
      verifier: MockVerifier.new
    )
  end

  def test_process_webhook
    projection = DummyProjection.new
    result = @client.process(
      payload: '{"delivery_id":"del_001","event_type":"intent.succeeded"}',
      signature_header: "t=123,v1=sig",
      projection: projection
    )

    assert_equal :processed, result[:status]
    assert projection.called
  end

  def test_parse_event
    event = @client.parse_event({
      delivery_id: "del_002",
      event_id: "evt_002",
      event_type: "charge.succeeded",
      data: { object: { id: "ch_002" } }
    })

    assert_equal "del_002", event.delivery_id
    assert_equal "ch_002", event.charge_id
  end
end
