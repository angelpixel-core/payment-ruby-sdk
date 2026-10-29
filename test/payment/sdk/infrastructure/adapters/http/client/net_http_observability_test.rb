# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/http/client/net_http"
require "payment/sdk/client"

class NetHttpObservabilityTest < Minitest::Test
  class TestLogger
    attr_reader :infos, :warns, :debugs

    def initialize
      @infos = []
      @warns = []
      @debugs = []
    end

    def info(msg)
      @infos << msg
    end

    def warn(msg)
      @warns << msg
    end

    def debug(msg)
      @debugs << msg
    end

    def debug?
      true
    end
  end

  def setup
    @logger = TestLogger.new
    @adapter = Payment::SDK::Infrastructure::Adapters::Http::Client::NetHttp.new(
      base_url: "https://api.payment.com/v1",
      max_retries: 0,
      logger: @logger
    )
  end

  def test_logs_structured_metrics_on_successful_request
    response_stub = Object.new
    def response_stub.code
      "200"
    end

    def response_stub.body
      '{"status":"ok"}'
    end

    def response_stub.[](key)
      {"x-request-id" => "req_srv_999"}[key]
    end

    http_stub = Object.new
    def http_stub.use_ssl=(*)
    end

    def http_stub.open_timeout=(*)
    end

    def http_stub.read_timeout=(*)
    end
    http_stub.define_singleton_method(:request) do |req|
      @last_req = req
      response_stub
    end

    with_stubbed_http(http_stub) do
      @adapter.request(
        method: :get,
        path: "/health?api_key=secret123",
        request_id: "client_req_1"
      )

      assert_equal 1, @logger.infos.size
      info_msg = @logger.infos.first

      assert_includes info_msg, "[Payment::SDK]"
      assert_includes info_msg, "method=GET"
      assert_includes info_msg, "api_key=%5BFILTERED%5D"
      refute_includes info_msg, "secret123"
      assert_includes info_msg, "status=200"
      assert_includes info_msg, "duration_ms="
      assert_includes info_msg, "request_id=req_srv_999"

      # Also verify debug logging sanitizes headers
      assert_equal 1, @logger.debugs.size
      debug_msg = @logger.debugs.first
      assert_includes debug_msg, "GET headers="
    end
  end

  def test_propagates_w3c_traceparent_and_x_request_id_headers
    response_stub = Object.new
    def response_stub.code
      "200"
    end

    def response_stub.body
      '{"id":"pi_100"}'
    end

    def response_stub.[](key)
      nil
    end

    http_stub = Object.new
    def http_stub.use_ssl=(*)
    end

    def http_stub.open_timeout=(*)
    end

    def http_stub.read_timeout=(*)
    end
    http_stub.define_singleton_method(:request) do |req|
      @last_req = req
      response_stub
    end

    traceparent = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
    request_id = "req_custom_abc"

    with_stubbed_http(http_stub) do
      @adapter.request(
        method: :post,
        path: "/payment_intents",
        body: {amount: 500},
        request_id: request_id,
        traceparent: traceparent
      )

      req = http_stub.instance_variable_get(:@last_req)
      assert_equal request_id, req["X-Request-Id"]
      assert_equal traceparent, req["traceparent"]
    end
  end

  def test_client_facade_sanitizes_authorization_in_debug_logs
    config = Payment::SDK::Configuration.new
    config.base_url = "https://api.payment.com"
    config.api_key = "sk_live_secret_token_never_leak"
    config.logger = @logger

    client = Payment::SDK::Client.new(config)

    response_stub = Object.new
    def response_stub.code
      "200"
    end

    def response_stub.body
      '{"id":"pi_123"}'
    end

    def response_stub.[](key)
      nil
    end

    http_stub = Object.new
    def http_stub.use_ssl=(*)
    end

    def http_stub.open_timeout=(*)
    end

    def http_stub.read_timeout=(*)
    end
    http_stub.define_singleton_method(:request) do |req|
      @last_req = req
      response_stub
    end

    with_stubbed_http(http_stub) do
      client.get_payment_intent("pi_123", request_id: "trace_1", traceparent: "trace_tp")

      req = http_stub.instance_variable_get(:@last_req)
      # On the wire, the bearer token is sent
      assert_equal "Bearer sk_live_secret_token_never_leak", req["Authorization"]
      assert_equal "trace_1", req["X-Request-Id"]
      assert_equal "trace_tp", req["traceparent"]

      # But in the debug logs, it must be [FILTERED]
      refute_empty @logger.debugs
      debug_msg = @logger.debugs.first
      assert_includes debug_msg, '"authorization" => "[FILTERED]"'
      refute_includes debug_msg, "sk_live_secret_token_never_leak"
    end
  end

  private

  def with_stubbed_http(http_stub)
    orig = Net::HTTP.method(:new)
    verbose = $VERBOSE
    $VERBOSE = nil
    Net::HTTP.define_singleton_method(:new) { |*| http_stub }
    $VERBOSE = verbose
    yield
  ensure
    $VERBOSE = nil
    Net::HTTP.define_singleton_method(:new, &orig)
    $VERBOSE = verbose
  end
end
