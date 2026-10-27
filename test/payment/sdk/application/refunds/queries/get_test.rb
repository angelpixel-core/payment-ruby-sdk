# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"
require "payment/sdk/application/refunds/queries/get"

class ApplicationRefundsQueriesGetTest < Minitest::Test
  class MockClient
    include Payment::SDK::Domain::Shared::Ports::Http::Client
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path }
    end
  end

  def test_executes_get_refund
    client = MockClient.new
    query = Payment::SDK::Application::Refunds::Queries::Get.new(client)
    query.execute(id: "re_123")

    req = client.last_request
    assert_equal :get, req[:method]
    assert_equal "/refunds/re_123", req[:path]
  end
end
