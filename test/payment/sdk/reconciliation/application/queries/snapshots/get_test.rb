# frozen_string_literal: true

require "test_helper"
require "payment/sdk/reconciliation/application/queries/snapshots/get"

class ReconciliationApplicationQueriesSnapshotsGetTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      [{ "payment_intent_id" => "pi_1", "status" => "succeeded" }]
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @query = Payment::SDK::Reconciliation::Application::Queries::Snapshots::Get.new(@http_client)
  end

  def test_call_includes_snapshot_view
    result = @query.call

    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/reports/transactions", @http_client.last_request[:path]
    assert_equal({ view: "snapshot" }, @http_client.last_request[:query_params])
    assert_equal [{ "payment_intent_id" => "pi_1", "status" => "succeeded" }], result
  end
end
