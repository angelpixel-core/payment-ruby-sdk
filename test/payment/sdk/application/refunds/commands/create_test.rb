# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"
require "payment/sdk/application/refunds/commands/create"

class ApplicationRefundsCommandsCreateTest < Minitest::Test
  class MockClient
    include Payment::SDK::Domain::Shared::Ports::Http::Client
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body }
    end
  end

  def setup
    @client = MockClient.new
    @cmd = Payment::SDK::Application::Refunds::Commands::Create.new(@client)
  end

  def test_requires_idempotency_key
    assert_raises(ArgumentError) do
      @cmd.execute(charge_id: "ch_1", amount: 500, reason: "duplicate", idempotency_key: nil)
    end
  end

  def test_executes_create_refund
    @cmd.execute(
      charge_id: "ch_123",
      amount: 500,
      reason: "duplicate",
      idempotency_key: "key-refund"
    )

    req = @client.last_request
    assert_equal :post, req[:method]
    assert_equal "/refunds", req[:path]
    assert_equal "key-refund", req[:headers]["Idempotency-Key"]
    assert_equal "ch_123", req[:body][:charge_id]
    assert_equal 500, req[:body][:amount]
    assert_equal "duplicate", req[:body][:reason]
  end
end
