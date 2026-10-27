# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/application/queries/lifecycles/get"

class PaymentsApplicationQueriesLifecyclesGetTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      { id: "pi_123", lifecycle: [] }
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @query = Payment::SDK::Payments::Application::Queries::Lifecycles::Get.new(@http_client)
  end

  def test_get_payment_lifecycle
    result = @query.call(id: "pi_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/payment_intents/pi_123/lifecycle", req[:path]
    assert_equal({ id: "pi_123", lifecycle: [] }, result)
  end
end
