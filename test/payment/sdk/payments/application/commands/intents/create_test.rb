# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/application/commands/intents/create"

class PaymentsApplicationCommandsIntentsCreateTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      { id: "pi_123", status: "requires_payment_method" }
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @command = Payment::SDK::Payments::Application::Commands::Intents::Create.new(@http_client)
  end

  def test_successful_create_payment_intent
    result = @command.call(
      amount: 2000,
      currency: "usd",
      merchant_id: "mer_1",
      customer_id: "cus_1",
      capture_method: "manual",
      idempotency_key: "ik_123"
    )

    req = @http_client.last_request
    assert_equal :post, req[:method]
    assert_equal "/payment_intents", req[:path]
    assert_equal "ik_123", req[:headers]["Idempotency-Key"]
    assert_equal 2000, req[:body][:amount]
    assert_equal "usd", req[:body][:currency]
    assert_equal "manual", req[:body][:capture_method]
    assert_equal "mer_1", req[:body][:merchant_id]
    assert_equal "cus_1", req[:body][:customer_id]
    assert_equal({ id: "pi_123", status: "requires_payment_method" }, result)
  end

  def test_requires_idempotency_key
    assert_raises(ArgumentError) do
      @command.call(amount: 1000, currency: "usd", idempotency_key: nil)
    end
  end
end
