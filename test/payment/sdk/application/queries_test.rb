# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/ports/http_client_port"
require "payment/sdk/application/queries/get_payment_intent"
require "payment/sdk/application/queries/get_payment_lifecycle"
require "payment/sdk/application/queries/get_payment_attempt"
require "payment/sdk/application/queries/get_charge"
require "payment/sdk/application/queries/get_refund"
require "payment/sdk/application/queries/get_transaction_report"
require "payment/sdk/application/queries/get_transaction_snapshot"

class MockQueryHttpClient
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

class QueriesTest < Minitest::Test
  def setup
    @http_client = MockQueryHttpClient.new
  end

  def test_get_payment_intent
    query = Payment::SDK::Application::Queries::GetPaymentIntent.new(@http_client)
    query.execute(id: "pi_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/payment_intents/pi_123", req[:path]
    assert_nil req[:headers]["Idempotency-Key"]
  end

  def test_get_payment_lifecycle
    query = Payment::SDK::Application::Queries::GetPaymentLifecycle.new(@http_client)
    query.execute(id: "pi_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/payment_intents/pi_123/lifecycle", req[:path]
  end

  def test_get_payment_attempt
    query = Payment::SDK::Application::Queries::GetPaymentAttempt.new(@http_client)
    query.execute(id: "pa_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/payment_attempts/pa_123", req[:path]
  end

  def test_get_charge
    query = Payment::SDK::Application::Queries::GetCharge.new(@http_client)
    query.execute(id: "ch_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/charges/ch_123", req[:path]
  end

  def test_get_refund
    query = Payment::SDK::Application::Queries::GetRefund.new(@http_client)
    query.execute(id: "re_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/refunds/re_123", req[:path]
  end

  def test_get_transaction_report
    query = Payment::SDK::Application::Queries::GetTransactionReport.new(@http_client)
    query.execute(start_date: "2024-01-01", end_date: "2024-01-31")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/reports/transactions", req[:path]
    assert_equal "2024-01-01", req[:query_params][:start_date]
    assert_equal "2024-01-31", req[:query_params][:end_date]
  end

  def test_get_transaction_snapshot
    query = Payment::SDK::Application::Queries::GetTransactionSnapshot.new(@http_client)
    query.execute

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/reports/transactions", req[:path]
    assert_equal "snapshot", req[:query_params][:view]
  end
end
