# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"
require "payment/sdk/interfaces/refunds/client"

class InterfacesRefundsClientTest < Minitest::Test
  class MockClient
    include Payment::SDK::Domain::Shared::Ports::Http::Client
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body }
    end
  end

  def setup
    @http_client = MockClient.new
    @refunds_client = Payment::SDK::Interfaces::Refunds::Client.new(@http_client)
  end

  def test_create_refund
    @refunds_client.create(
      charge_id: "ch_123",
      amount: 500,
      reason: "duplicate",
      idempotency_key: "k_ref"
    )

    req = @http_client.last_request
    assert_equal :post, req[:method]
    assert_equal "/refunds", req[:path]
    assert_equal "k_ref", req[:headers]["Idempotency-Key"]
    assert_equal "ch_123", req[:body][:charge_id]
  end

  def test_get_refund
    @refunds_client.get("re_123")

    req = @http_client.last_request
    assert_equal :get, req[:method]
    assert_equal "/refunds/re_123", req[:path]
  end
end
