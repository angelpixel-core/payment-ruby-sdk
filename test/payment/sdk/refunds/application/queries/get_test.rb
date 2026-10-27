# frozen_string_literal: true

require "test_helper"
require "payment/sdk/refunds/application/queries/get"

class RefundsApplicationQueriesGetTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      { id: "re_123", amount: 500 }
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @query = Payment::SDK::Refunds::Application::Queries::Get.new(@http_client)
  end

  def test_get_refund
    result = @query.call(id: "re_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/refunds/re_123", req[:path]
    assert_equal({ id: "re_123", amount: 500 }, result)
  end
end
