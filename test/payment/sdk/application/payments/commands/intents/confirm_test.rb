# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"
require "payment/sdk/application/payments/commands/intents/confirm"

class PaymentsCommandsIntentsConfirmTest < Minitest::Test
  class MockClient
    include Payment::SDK::Domain::Shared::Ports::Http::Client
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body }
    end
  end

  def setup
    @client = MockClient.new
    @cmd = Payment::SDK::Application::Payments::Commands::Intents::Confirm.new(@client)
  end

  def test_executes_confirm
    @cmd.execute(
      id: "pi_123",
      payment_method_token: "pm_token",
      idempotency_key: "key-confirm",
      scenario: "declined"
    )

    req = @client.last_request
    assert_equal :post, req[:method]
    assert_equal "/payment_intents/pi_123/confirm", req[:path]
    assert_equal "key-confirm", req[:headers]["Idempotency-Key"]
    assert_equal "declined", req[:headers]["X-Sandbox-Scenario"]
    assert_equal "pm_token", req[:body][:payment_method_token]
  end
end
