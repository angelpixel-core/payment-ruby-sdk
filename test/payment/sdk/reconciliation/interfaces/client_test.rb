# frozen_string_literal: true

require "test_helper"
require "payment/sdk/reconciliation/interfaces/client"

class ReconciliationInterfacesClientTest < Minitest::Test
  class MockHttpClient
    attr_reader :last_request

    def request(method:, path:, headers: {}, body: nil, query_params: {})
      @last_request = { method: method, path: path, headers: headers, body: body, query_params: query_params }
      if query_params[:view] == "snapshot"
        [{ payment_intent_id: "pi_123", status: "succeeded", amount: 1000 }]
      else
        [{ id: "rep_1", transactions: 1 }]
      end
    end
  end

  def setup
    @http_client = MockHttpClient.new
    @client = Payment::SDK::Reconciliation::Interfaces::Client.new(http_client: @http_client)
  end

  def test_get_report
    report = @client.get_report(start_date: "2026-01-01")

    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/reports/transactions", @http_client.last_request[:path]
    assert_equal({ start_date: "2026-01-01" }, @http_client.last_request[:query_params])
    assert_equal [{ id: "rep_1", transactions: 1 }], report
  end

  def test_get_snapshot
    snapshot = @client.get_snapshot

    assert_equal :get, @http_client.last_request[:method]
    assert_equal "/reports/transactions", @http_client.last_request[:path]
    assert_equal({ view: "snapshot" }, @http_client.last_request[:query_params])
    assert_equal [{ payment_intent_id: "pi_123", status: "succeeded", amount: 1000 }], snapshot
  end

  def test_reconcile
    local_records = [
      { payment_intent_id: "pi_123", status: "succeeded", amount: 1000 }
    ]

    results = @client.reconcile(local_records: local_records, run_id: "run_test_1")

    assert_equal 1, results.size
    assert_equal :match, results.first[:status]
    assert_equal "run_test_1:pi_123", results.first[:id]
  end
end
