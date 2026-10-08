# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/http/net_http_adapter"

class NetHttpAdapterTest < Minitest::Test
  def setup
    @adapter = Payment::SDK::Infrastructure::Http::NetHttpAdapter.new(
      base_url: "https://api.payment.com/v1",
      max_retries: 2
    )
  end

  def test_successful_get_request
    response_stub = Object.new
    def response_stub.code; "200"; end
    def response_stub.body; '{"id":"pi_123"}'; end

    http_stub = Object.new
    def http_stub.use_ssl=(v); end
    def http_stub.open_timeout=(v); end
    def http_stub.read_timeout=(v); end
    http_stub.define_singleton_method(:request) do |req|
      @last_request = req
      response_stub
    end

    with_stubbed_http(http_stub) do
      result = @adapter.request(method: :get, path: "/payment_intents/pi_123")
      assert_equal({ id: "pi_123" }, result)
      
      req = http_stub.instance_variable_get(:@last_request)
      assert_instance_of Net::HTTP::Get, req
    end
  end

  def test_successful_post_request_with_body_and_headers
    response_stub = Object.new
    def response_stub.code; "201"; end
    def response_stub.body; '{"id":"pi_123"}'; end

    http_stub = Object.new
    def http_stub.use_ssl=(v); end
    def http_stub.open_timeout=(v); end
    def http_stub.read_timeout=(v); end
    http_stub.define_singleton_method(:request) do |req|
      @last_request = req
      response_stub
    end

    with_stubbed_http(http_stub) do
      result = @adapter.request(
        method: :post,
        path: "/payment_intents",
        headers: { "Idempotency-Key" => "key-123" },
        body: { amount: 1000 }
      )
      assert_equal({ id: "pi_123" }, result)
      
      req = http_stub.instance_variable_get(:@last_request)
      assert_instance_of Net::HTTP::Post, req
      assert_equal "key-123", req["Idempotency-Key"]
      assert_equal '{"amount":1000}', req.body
    end
  end

  def test_retries_on_timeout
    attempts = 0
    
    http_stub = Object.new
    def http_stub.use_ssl=(v); end
    def http_stub.open_timeout=(v); end
    def http_stub.read_timeout=(v); end
    http_stub.define_singleton_method(:request) do |req|
      attempts += 1
      if attempts <= 2
        raise Net::ReadTimeout, "Timeout"
      else
        response = Object.new
        def response.code; "200"; end
        def response.body; '{"ok":true}'; end
        response
      end
    end

    with_stubbed_http(http_stub) do
      # Avoid sleeping during tests
      @adapter.define_singleton_method(:sleep_for_backoff) { |count| }
      
      result = @adapter.request(method: :get, path: "/test")
      assert_equal({ ok: true }, result)
      assert_equal 3, attempts
    end
  end

  def test_fails_after_max_retries
    attempts = 0
    
    http_stub = Object.new
    def http_stub.use_ssl=(v); end
    def http_stub.open_timeout=(v); end
    def http_stub.read_timeout=(v); end
    http_stub.define_singleton_method(:request) do |req|
      attempts += 1
      raise Net::ReadTimeout, "Timeout"
    end

    with_stubbed_http(http_stub) do
      # Avoid sleeping during tests
      @adapter.define_singleton_method(:sleep_for_backoff) { |count| }
      
      assert_raises(Payment::SDK::TimeoutError) do
        @adapter.request(method: :get, path: "/test")
      end
      assert_equal 3, attempts
    end
  end

  private

  def with_stubbed_http(http_stub)
    original_method = Net::HTTP.method(:new)
    Net::HTTP.define_singleton_method(:new) { |*args| http_stub }
    yield
  ensure
    Net::HTTP.define_singleton_method(:new, &original_method)
  end
end
