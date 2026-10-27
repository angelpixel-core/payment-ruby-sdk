# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"
require "payment/sdk/application/payments/commands/intents/create"

class MockPaymentHttpClient
  include Payment::SDK::Domain::Shared::Ports::Http::Client

  attr_reader :last_request

  def request(method:, path:, headers: {}, body: nil, query_params: {})
    @last_request = {
      method: method,
      path: path,
      headers: headers,
      body: body,
      query_params: query_params
    }
  end
end

class PaymentsCommandsIntentsCreateTest < Minitest::Test
  def setup
    @http_client = MockPaymentHttpClient.new
    @cmd = Payment::SDK::Application::Payments::Commands::Intents::Create.new(@http_client)
  end

  def test_requires_idempotency_key
    assert_raises(ArgumentError) do
      @cmd.execute(
        amount: 1000, currency: "usd", merchant_id: "m_1",
        customer_id: "c_1", capture_method: "automatic", idempotency_key: nil
      )
    end
  end

  def test_executes_successfully
    @cmd.execute(
      amount: 1000,
      currency: "USD",
      merchant_id: "mer_123",
      customer_id: "cus_123",
      capture_method: "manual",
      idempotency_key: "key-123"
    )

    req = @http_client.last_request
    assert_equal :post, req[:method]
    assert_equal "/payment_intents", req[:path]
    assert_equal "key-123", req[:headers]["Idempotency-Key"]
    assert_equal 1000, req[:body][:amount]
    assert_equal "usd", req[:body][:currency]
    assert_equal "manual", req[:body][:capture_method]
  end
end
