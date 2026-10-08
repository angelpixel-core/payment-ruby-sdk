# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/ports/http_client_port"
require "payment/sdk/application/commands/create_payment_intent"
require "payment/sdk/application/commands/confirm_payment_intent"
require "payment/sdk/application/commands/capture_payment_intent"
require "payment/sdk/application/commands/create_refund"

class MockHttpClient
  include Payment::SDK::Domain::Ports::HttpClientPort

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

class CommandsTest < Minitest::Test
  def setup
    @http_client = MockHttpClient.new
  end

  def test_base_command_requires_idempotency_key
    cmd = Payment::SDK::Application::Commands::CreatePaymentIntent.new(@http_client)
    
    assert_raises(ArgumentError) do
      cmd.execute(
        amount: 1000, currency: "usd", merchant_id: "m_1",
        customer_id: "c_1", capture_method: "automatic", idempotency_key: nil
      )
    end
    
    assert_raises(ArgumentError) do
      cmd.execute(
        amount: 1000, currency: "usd", merchant_id: "m_1",
        customer_id: "c_1", capture_method: "automatic", idempotency_key: "   "
      )
    end
  end

  def test_create_payment_intent
    cmd = Payment::SDK::Application::Commands::CreatePaymentIntent.new(@http_client)
    cmd.execute(
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

  def test_confirm_payment_intent
    cmd = Payment::SDK::Application::Commands::ConfirmPaymentIntent.new(@http_client)
    cmd.execute(
      id: "pi_123",
      payment_method_token: "pm_token",
      idempotency_key: "key-confirm",
      scenario: "declined"
    )

    req = @http_client.last_request
    assert_equal :post, req[:method]
    assert_equal "/payment_intents/pi_123/confirm", req[:path]
    assert_equal "key-confirm", req[:headers]["Idempotency-Key"]
    assert_equal "declined", req[:headers]["X-Sandbox-Scenario"]
    assert_equal "pm_token", req[:body][:payment_method_token]
  end

  def test_capture_payment_intent
    cmd = Payment::SDK::Application::Commands::CapturePaymentIntent.new(@http_client)
    cmd.execute(
      id: "pi_123",
      amount: 500,
      idempotency_key: "key-capture"
    )

    req = @http_client.last_request
    assert_equal :post, req[:method]
    assert_equal "/payment_intents/pi_123/capture", req[:path]
    assert_equal "key-capture", req[:headers]["Idempotency-Key"]
    assert_equal 500, req[:body][:amount]
  end

  def test_create_refund
    cmd = Payment::SDK::Application::Commands::CreateRefund.new(@http_client)
    cmd.execute(
      charge_id: "ch_123",
      amount: 500,
      reason: "duplicate",
      idempotency_key: "key-refund"
    )

    req = @http_client.last_request
    assert_equal :post, req[:method]
    assert_equal "/refunds", req[:path]
    assert_equal "key-refund", req[:headers]["Idempotency-Key"]
    assert_equal "ch_123", req[:body][:charge_id]
    assert_equal 500, req[:body][:amount]
    assert_equal "duplicate", req[:body][:reason]
  end
end
