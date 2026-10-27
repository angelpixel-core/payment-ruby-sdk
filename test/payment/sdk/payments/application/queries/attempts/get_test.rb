# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/application/queries/attempts/get"

class PaymentsApplicationQueriesAttemptsGetTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      { id: "pa_123", status: "succeeded" }
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @query = Payment::SDK::Payments::Application::Queries::Attempts::Get.new(@http_client)
  end

  def test_get_payment_attempt
    result = @query.call(id: "pa_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/payment_attempts/pa_123", req[:path]
    assert_equal({ id: "pa_123", status: "succeeded" }, result)
  end
end
