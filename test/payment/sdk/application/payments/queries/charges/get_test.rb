# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"
require "payment/sdk/application/payments/queries/charges/get"

class PaymentsQueriesChargesGetTest < Minitest::Test
  class MockClient
    include Payment::SDK::Domain::Shared::Ports::Http::Client
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path }
    end
  end

  def test_executes_get_charge
    client = MockClient.new
    query = Payment::SDK::Application::Payments::Queries::Charges::Get.new(client)
    query.execute(id: "ch_123")

    req = client.last_request
    assert_equal :get, req[:method]
    assert_equal "/charges/ch_123", req[:path]
  end
end
