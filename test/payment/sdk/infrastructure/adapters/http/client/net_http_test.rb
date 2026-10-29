# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/http/client/net_http"

class InfrastructureAdaptersHttpClientNetHttpTest < Minitest::Test
  def setup
    @adapter = Payment::SDK::Infrastructure::Adapters::Http::Client::NetHttp.new(
      base_url: "https://api.payment.com/v1",
      max_retries: 2
    )
  end

  def test_successful_get_request
    response_stub = Object.new
    def response_stub.code
      "200"
    end

    def response_stub.body
      '{"id":"pi_123"}'
    end

    http_stub = Object.new
    def http_stub.use_ssl=(v)
    end

    def http_stub.open_timeout=(v)
    end

    def http_stub.read_timeout=(v)
    end
    http_stub.define_singleton_method(:request) do |req|
      @last_request = req
      response_stub
    end

    with_stubbed_http(http_stub) do
      result = @adapter.request(method: :get, path: "/payment_intents/pi_123")
      assert_equal({id: "pi_123"}, result)

      req = http_stub.instance_variable_get(:@last_request)
      assert_instance_of Net::HTTP::Get, req
    end
  end

  def test_successful_post_request_with_body_and_headers
    response_stub = Object.new
    def response_stub.code
      "201"
    end

    def response_stub.body
      '{"id":"pi_123"}'
    end

    http_stub = Object.new
    def http_stub.use_ssl=(v)
    end

    def http_stub.open_timeout=(v)
    end

    def http_stub.read_timeout=(v)
    end
    http_stub.define_singleton_method(:request) do |req|
      @last_request = req
      response_stub
    end

    with_stubbed_http(http_stub) do
      result = @adapter.request(
        method: :post,
        path: "/payment_intents",
        headers: {"Idempotency-Key" => "key-123"},
        body: {amount: 1000}
      )
      assert_equal({id: "pi_123"}, result)

      req = http_stub.instance_variable_get(:@last_request)
      assert_instance_of Net::HTTP::Post, req
      assert_equal "key-123", req["Idempotency-Key"]
      assert_equal "application/json", req["Content-Type"]
      assert_equal '{"amount":1000}', req.body
    end
  end

  FakeResponse = Struct.new(:code, :body, :headers) do
    def [](h)
      headers&.[](h)
    end
  end

  def test_rate_limit_retry_on_429
    call_count = 0
    http_stub = Object.new
    def http_stub.use_ssl=(v)
    end

    def http_stub.open_timeout=(v)
    end

    def http_stub.read_timeout=(v)
    end

    http_stub.define_singleton_method(:request) do |_req|
      call_count += 1
      if call_count == 1
        FakeResponse.new("429", '{"message":"rate limit"}', {"retry-after" => "0"})
      else
        FakeResponse.new("200", '{"status":"ok"}', nil)
      end
    end

    with_stubbed_http(http_stub) do
      result = @adapter.request(method: :get, path: "/check")
      assert_equal({status: "ok"}, result)
      assert_equal 2, call_count
    end
  end

  def test_rate_limit_exceeds_max_delay_raises_immediately
    call_count = 0
    http_stub = Object.new
    def http_stub.use_ssl=(v)
    end

    def http_stub.open_timeout=(v)
    end

    def http_stub.read_timeout=(v)
    end

    http_stub.define_singleton_method(:request) do |_req|
      call_count += 1
      FakeResponse.new("429", '{"message":"slow down"}', {"retry-after" => "60"})
    end

    with_stubbed_http(http_stub) do
      error = assert_raises(Payment::SDK::RateLimitError) do
        @adapter.request(method: :get, path: "/slow")
      end
      assert_equal 60, error.retry_after_seconds
      assert_equal 1, call_count
    end
  end

  def test_circuit_breaker_trips_and_blocks_further_requests
    cb = Payment::SDK::Infrastructure::Resilience::CircuitBreaker.new(
      failure_threshold: 2,
      reset_timeout: 30
    )

    cb_adapter = Payment::SDK::Infrastructure::Adapters::Http::Client::NetHttp.new(
      base_url: "https://api.payment.com/v1",
      max_retries: 0,
      circuit_breaker: cb
    )

    call_count = 0
    http_stub = Object.new
    def http_stub.use_ssl=(v)
    end

    def http_stub.open_timeout=(v)
    end

    def http_stub.read_timeout=(v)
    end

    http_stub.define_singleton_method(:request) do |_req|
      call_count += 1
      FakeResponse.new("500", '{"error_code":"internal_error"}', nil)
    end

    with_stubbed_http(http_stub) do
      # 1st failure
      assert_raises(Payment::SDK::UpstreamError) do
        cb_adapter.request(method: :get, path: "/fail")
      end
      assert cb.closed?

      # 2nd failure trips circuit
      assert_raises(Payment::SDK::UpstreamError) do
        cb_adapter.request(method: :get, path: "/fail")
      end
      assert cb.open?
      assert_equal 2, call_count

      # 3rd request is blocked by circuit breaker before network
      error = assert_raises(Payment::SDK::CircuitBreakerOpenError) do
        cb_adapter.request(method: :get, path: "/fail")
      end
      assert_includes error.message, "Circuit breaker is OPEN"
      assert_equal 2, call_count # network was NOT called!
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
