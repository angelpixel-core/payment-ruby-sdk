# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"
require "payment/sdk/application/payments/commands/intents/capture"

class PaymentsCommandsIntentsCaptureTest < Minitest::Test
  class MockClient
    include Payment::SDK::Domain::Shared::Ports::Http::Client
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body }
    end
  end

  def setup
    @client = MockClient.new
    @cmd = Payment::SDK::Application::Payments::Commands::Intents::Capture.new(@client)
  end

  def test_executes_capture
    @cmd.execute(
      id: "pi_123",
      amount: 500,
      idempotency_key: "key-capture"
    )

    req = @client.last_request
    assert_equal :post, req[:method]
    assert_equal "/payment_intents/pi_123/capture", req[:path]
    assert_equal "key-capture", req[:headers]["Idempotency-Key"]
    assert_equal 500, req[:body][:amount]
  end
end
