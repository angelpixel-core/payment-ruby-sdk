# frozen_string_literal: true

require "test_helper"
require "payment/sdk/application/reconciliation/queries/snapshots/get"

class ApplicationReconciliationQueriesSnapshotsGetTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      [{ "payment_intent_id" => "pi_1", "status" => "succeeded" }]
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @query = Payment::SDK::Application::Reconciliation::Queries::Snapshots::Get.new(@http_client)
  end

  def test_execute_includes_snapshot_view
    result = @query.execute

    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/reports/transactions", @http_client.last_request[:path]
    assert_equal({ view: "snapshot" }, @http_client.last_request[:query_params])
    assert_equal [{ "payment_intent_id" => "pi_1", "status" => "succeeded" }], result
  end

  def test_execute_with_date_range
    @query.execute(start_date: "2026-02-01", end_date: "2026-02-28")

    expected_params = { view: "snapshot", start_date: "2026-02-01", end_date: "2026-02-28" }
    assert_equal expected_params, @http_client.last_request[:query_params]
  end
end
