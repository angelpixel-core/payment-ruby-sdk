# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/application/commands/intents/capture"

class PaymentsApplicationCommandsIntentsCaptureTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = {method: method, path: path, headers: headers, body: body, query_params: query_params}
      {id: "pi_123", status: "succeeded", captured_amount: 500}
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @command = Payment::SDK::Payments::Application::Commands::Intents::Capture.new(@http_client)
  end

  def test_successful_capture_payment_intent
    result = @command.call(id: "pi_123", amount: 500, idempotency_key: "ik_cap")

    req = @http_client.last_request
    assert_equal :post, req[:method]
    assert_equal "/payment_intents/pi_123/capture", req[:path]
    assert_equal "ik_cap", req[:headers]["Idempotency-Key"]
    assert_equal 500, req[:body][:amount]
    assert_equal 500, result[:captured_amount]
  end
end
