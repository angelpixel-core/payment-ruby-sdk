# frozen_string_literal: true

require "test_helper"
require "payment/sdk/payments/application/queries/charges/get"

class PaymentsApplicationQueriesChargesGetTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      { id: "ch_123", amount: 1000 }
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @query = Payment::SDK::Payments::Application::Queries::Charges::Get.new(@http_client)
  end

  def test_get_charge
    result = @query.call(id: "ch_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/charges/ch_123", req[:path]
    assert_equal({ id: "ch_123", amount: 1000 }, result)
  end
end
