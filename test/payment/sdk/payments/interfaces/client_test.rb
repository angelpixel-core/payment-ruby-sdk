# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/interfaces/client"

class PaymentsInterfacesClientTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      { id: "res_123", status: "succeeded" }
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @client = Payment::SDK::Payments::Interfaces::Client.new(@http_client)
  end

  def test_intents_resource_create
    @client.intents.create(amount: 1000, currency: "usd", idempotency_key: "ik_1")
    assert_equal :post, @http_client.last_request[:method]
    assert_equal "/payment_intents", @http_client.last_request[:path]
  end

  def test_intents_resource_confirm
    @client.intents.confirm("pi_1", payment_method_token: "tok_1", idempotency_key: "ik_2")
    assert_equal :post, @http_client.last_request[:method]
    assert_equal "/payment_intents/pi_1/confirm", @http_client.last_request[:path]
  end

  def test_intents_resource_capture
    @client.intents.capture("pi_1", amount: 500, idempotency_key: "ik_3")
    assert_equal :post, @http_client.last_request[:method]
    assert_equal "/payment_intents/pi_1/capture", @http_client.last_request[:path]
  end

  def test_intents_resource_get
    @client.intents.get("pi_1")
    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/payment_intents/pi_1", @http_client.last_request[:path]
  end

  def test_intents_resource_get_lifecycle
    @client.intents.get_lifecycle("pi_1")
    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/payment_intents/pi_1/lifecycle", @http_client.last_request[:path]
  end

  def test_charges_resource_get
    @client.charges.get("ch_1")
    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/charges/ch_1", @http_client.last_request[:path]
  end

  def test_attempts_resource_get
    @client.attempts.get("pa_1")
    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/payment_attempts/pa_1", @http_client.last_request[:path]
  end
end
