# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/http/error_mapper"
require "json"

class ErrorMapperTest < Minitest::Test
  MockResponse = Struct.new(:code, :body)

  def test_maps_invalid_amount_to_invalid_request_error
    response = MockResponse.new("400", { error_code: "invalid_amount", message: "Bad amount" }.to_json)
    
    error = assert_raises(Payment::SDK::InvalidRequestError) do
      Payment::SDK::Infrastructure::Http::ErrorMapper.map_error(response)
    end
    
    assert_equal 400, error.status_code
    assert_equal "invalid_amount", error.code
    assert_equal "Bad amount", error.message
  end

  def test_maps_payment_intent_not_found_to_payment_not_found_error
    response = MockResponse.new("404", { error_code: "payment_intent_not_found", message: "Not found" }.to_json)
    
    error = assert_raises(Payment::SDK::PaymentNotFoundError) do
      Payment::SDK::Infrastructure::Http::ErrorMapper.map_error(response)
    end
    
    assert_equal 404, error.status_code
    assert_equal "payment_intent_not_found", error.code
  end

  def test_maps_idempotency_conflict_to_duplicate_request_error
    response = MockResponse.new("409", { error_code: "idempotency_conflict" }.to_json)
    
    error = assert_raises(Payment::SDK::DuplicateRequestError) do
      Payment::SDK::Infrastructure::Http::ErrorMapper.map_error(response)
    end
  end

  def test_maps_internal_error_to_upstream_error
    response = MockResponse.new("500", { error_code: "internal_error" }.to_json)
    
    error = assert_raises(Payment::SDK::UpstreamError) do
      Payment::SDK::Infrastructure::Http::ErrorMapper.map_error(response)
    end
  end

  def test_fallback_500_to_upstream_error
    response = MockResponse.new("502", "Bad Gateway") # Non-JSON body
    
    error = assert_raises(Payment::SDK::UpstreamError) do
      Payment::SDK::Infrastructure::Http::ErrorMapper.map_error(response)
    end
    
    assert_equal 502, error.status_code
    assert_equal "unknown_error", error.code
    assert_equal "Bad Gateway", error.raw_body
  end

  def test_success_does_not_raise
    response = MockResponse.new("200", { id: "pi_123" }.to_json)
    # Should not raise anything
    Payment::SDK::Infrastructure::Http::ErrorMapper.map_error(response)
  end
end
