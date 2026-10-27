# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/application/commands/intents/confirm"

class PaymentsApplicationCommandsIntentsConfirmTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      { id: "pi_123", status: "succeeded" }
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @command = Payment::SDK::Payments::Application::Commands::Intents::Confirm.new(@http_client)
  end

  def test_successful_confirm_payment_intent
    result = @command.call(
      id: "pi_123",
      payment_method_token: "pm_tok_visa",
      idempotency_key: "ik_conf",
      scenario: "declined"
    )

    req = @http_client.last_request
    assert_equal :post, req[:method]
    assert_equal "/payment_intents/pi_123/confirm", req[:path]
    assert_equal "ik_conf", req[:headers]["Idempotency-Key"]
    assert_equal "declined", req[:headers]["X-Sandbox-Scenario"]
    assert_equal "pm_tok_visa", req[:body][:payment_method_token]
    assert_equal({ id: "pi_123", status: "succeeded" }, result)
  end
end
