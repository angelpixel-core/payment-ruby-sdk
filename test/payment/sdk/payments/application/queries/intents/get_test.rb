# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/application/queries/intents/get"

class PaymentsApplicationQueriesIntentsGetTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = {method: method, path: path, headers: headers, body: body, query_params: query_params}
      {id: "pi_123", status: "requires_payment_method"}
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @query = Payment::SDK::Payments::Application::Queries::Intents::Get.new(@http_client)
  end

  def test_get_payment_intent
    result = @query.call(id: "pi_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/payment_intents/pi_123", req[:path]
    assert_equal({id: "pi_123", status: "requires_payment_method"}, result)
  end
end
