# frozen_string_literal: true

require "test_helper"
require "payment/sdk/application/reconciliation/queries/reports/get"

class ApplicationReconciliationQueriesReportsGetTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      [{ "id" => "rep_1", "total" => 100 }]
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @query = Payment::SDK::Application::Reconciliation::Queries::Reports::Get.new(@http_client)
  end

  def test_execute_without_params
    result = @query.execute

    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/reports/transactions", @http_client.last_request[:path]
    assert_empty @http_client.last_request[:query_params]
    assert_equal [{ "id" => "rep_1", "total" => 100 }], result
  end

  def test_execute_with_date_range
    @query.execute(start_date: "2026-01-01", end_date: "2026-01-31")

    expected_params = { start_date: "2026-01-01", end_date: "2026-01-31" }
    assert_equal expected_params, @http_client.last_request[:query_params]
  end
end
