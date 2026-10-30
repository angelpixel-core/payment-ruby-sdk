# frozen_string_literal: true

require "test_helper"
require "payment/sdk/refunds/interfaces/client"

class RefundsInterfacesClientTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = {method: method, path: path, headers: headers, body: body, query_params: query_params}
      {id: "re_123", status: "succeeded"}
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @client = Payment::SDK::Refunds::Interfaces::Client.new(@http_client)
  end

  def test_create_refund
    @client.create(charge_id: "ch_123", amount: 500, idempotency_key: "ik_ref")
    assert_equal :post, @http_client.last_request[:method]
    assert_equal "/refunds", @http_client.last_request[:path]
  end

  def test_get_refund
    @client.get("re_123")
    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/refunds/re_123", @http_client.last_request[:path]
  end
end
