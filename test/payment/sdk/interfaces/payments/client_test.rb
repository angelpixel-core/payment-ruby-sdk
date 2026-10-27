# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"
require "payment/sdk/interfaces/payments/client"

class InterfacesPaymentsClientTest < Minitest::Test
  class MockClient
    include Payment::SDK::Domain::Shared::Ports::Http::Client
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body }
    end
  end

  def setup
    @http_client = MockClient.new
    @payments_client = Payment::SDK::Interfaces::Payments::Client.new(@http_client)
  end

  def test_intents_create
    @payments_client.intents.create(
      amount: 1000,
      currency: "USD",
      merchant_id: "m_1",
      customer_id: "c_1",
      capture_method: "automatic",
      idempotency_key: "k_1"
    )

    assert_equal :post, @http_client.last_request[:method]
    assert_equal "/payment_intents", @http_client.last_request[:path]
  end

  def test_intents_confirm
    @payments_client.intents.confirm("pi_123", payment_method_token: "pm_tok", idempotency_key: "k_2")
    assert_equal :post, @http_client.last_request[:method]
    assert_equal "/payment_intents/pi_123/confirm", @http_client.last_request[:path]
  end

  def test_intents_capture
    @payments_client.intents.capture("pi_123", amount: 500, idempotency_key: "k_3")
    assert_equal :post, @http_client.last_request[:method]
    assert_equal "/payment_intents/pi_123/capture", @http_client.last_request[:path]
  end

  def test_intents_get
    @payments_client.intents.get("pi_123")
    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/payment_intents/pi_123", @http_client.last_request[:path]
  end

  def test_intents_get_lifecycle
    @payments_client.intents.get_lifecycle("pi_123")
    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/payment_intents/pi_123/lifecycle", @http_client.last_request[:path]
  end

  def test_charges_get
    @payments_client.charges.get("ch_123")
    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/charges/ch_123", @http_client.last_request[:path]
  end

  def test_attempts_get
    @payments_client.attempts.get("pa_123")
    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/payment_attempts/pa_123", @http_client.last_request[:path]
  end
end
