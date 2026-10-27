# frozen_string_literal: true

require "test_helper"
require "payment/sdk/refunds/application/commands/create"

class RefundsApplicationCommandsCreateTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      { id: "re_123", status: "succeeded" }
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @command = Payment::SDK::Refunds::Application::Commands::Create.new(@http_client)
  end

  def test_successful_create_refund
    result = @command.call(
      charge_id: "ch_123",
      amount: 500,
      reason: "requested_by_customer",
      idempotency_key: "ik_ref"
    )

    req = @http_client.last_request
    assert_equal :post, req[:method]
    assert_equal "/refunds", req[:path]
    assert_equal "ik_ref", req[:headers]["Idempotency-Key"]
    assert_equal "ch_123", req[:body][:charge_id]
    assert_equal 500, req[:body][:amount]
    assert_equal "requested_by_customer", req[:body][:reason]
    assert_equal({ id: "re_123", status: "succeeded" }, result)
  end
end
