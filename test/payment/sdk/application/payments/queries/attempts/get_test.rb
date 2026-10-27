# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"
require "payment/sdk/application/payments/queries/attempts/get"

class PaymentsQueriesAttemptsGetTest < Minitest::Test
  class MockClient
    include Payment::SDK::Domain::Shared::Ports::Http::Client
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path }
    end
  end

  def test_executes_get_attempt
    client = MockClient.new
    query = Payment::SDK::Application::Payments::Queries::Attempts::Get.new(client)
    query.execute(id: "pa_123")

    req = client.last_request
    assert_equal :get, req[:method]
    assert_equal "/payment_attempts/pa_123", req[:path]
  end
end
