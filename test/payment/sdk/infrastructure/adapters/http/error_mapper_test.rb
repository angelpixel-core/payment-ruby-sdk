# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/http/error_mapper"
require "json"

class InfrastructureAdaptersHttpErrorMapperTest < Minitest::Test
  MockResponse = Struct.new(:code, :body, :headers) do
    def [](header)
      headers&.[](header) || headers&.[](header.downcase)
    end
  end

  def test_maps_invalid_amount_to_invalid_request_error
    response = MockResponse.new("400", {error_code: "invalid_amount", message: "Bad amount"}.to_json)

    error = assert_raises(Payment::SDK::InvalidRequestError) do
      Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper.map_error(response)
    end

    assert_equal 400, error.status_code
    assert_equal "invalid_amount", error.code
    assert_equal "Bad amount", error.message
  end

  def test_maps_payment_intent_not_found_to_payment_not_found_error
    response = MockResponse.new("404", {error_code: "payment_intent_not_found", message: "Not found"}.to_json)

    error = assert_raises(Payment::SDK::PaymentNotFoundError) do
      Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper.map_error(response)
    end

    assert_equal 404, error.status_code
    assert_equal "payment_intent_not_found", error.code
  end

  def test_maps_idempotency_conflict_to_duplicate_request_error
    response = MockResponse.new("409", {error_code: "idempotency_conflict"}.to_json)

    error = assert_raises(Payment::SDK::DuplicateRequestError) do
      Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper.map_error(response)
    end

    assert_equal 409, error.status_code
  end

  def test_maps_internal_error_to_upstream_error
    response = MockResponse.new("500", {error_code: "internal_error"}.to_json)

    assert_raises(Payment::SDK::UpstreamError) do
      Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper.map_error(response)
    end
  end

  def test_fallback_500_to_upstream_error
    response = MockResponse.new("502", "Bad Gateway") # Non-JSON body

    error = assert_raises(Payment::SDK::UpstreamError) do
      Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper.map_error(response)
    end

    assert_equal 502, error.status_code
    assert_equal "unknown_error", error.code
    assert_equal "Bad Gateway", error.raw_body
  end

  def test_success_does_not_raise
    response = MockResponse.new("200", {id: "pi_123"}.to_json)
    # Should not raise anything
    Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper.map_error(response)
  end

  def test_maps_429_to_rate_limit_error_with_integer_retry_after
    response = MockResponse.new("429", {error_code: "rate_limit_exceeded", message: "Too many requests"}.to_json, {"retry-after" => "15"})

    error = assert_raises(Payment::SDK::RateLimitError) do
      Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper.map_error(response)
    end

    assert_equal 429, error.status_code
    assert_equal "rate_limit_exceeded", error.code
    assert_equal 15, error.retry_after_seconds
  end

  def test_maps_429_to_rate_limit_error_with_http_date_retry_after
    future_time = Time.now + 25
    response = MockResponse.new("429", {message: "Calm down"}.to_json, {"retry-after" => future_time.httpdate})

    error = assert_raises(Payment::SDK::RateLimitError) do
      Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper.map_error(response)
    end

    assert_equal 429, error.status_code
    assert error.retry_after_seconds.between?(20, 30)
  end

  def test_zero_pii_sanitization_in_api_error
    raw_payload = {
      error_code: "invalid_amount",
      message: "Rejected card",
      details: {
        card_number: "4111222233334444",
        cvv: "123",
        api_key: "sk_secret_123"
      }
    }.to_json

    response = MockResponse.new("400", raw_payload)

    error = assert_raises(Payment::SDK::InvalidRequestError) do
      Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper.map_error(response)
    end

    # Details are masked
    assert_equal "[FILTERED]", error.details["card_number"]
    assert_equal "[FILTERED]", error.details["cvv"]
    assert_equal "[FILTERED]", error.details["api_key"]

    # Raw body is masked
    refute_includes error.raw_body, "4111222233334444"
    refute_includes error.raw_body, "sk_secret_123"
    assert_includes error.raw_body, "[FILTERED]"
  end
end
