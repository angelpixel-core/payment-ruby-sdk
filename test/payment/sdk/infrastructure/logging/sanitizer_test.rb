# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/logging/sanitizer"

class InfrastructureLoggingSanitizerTest < Minitest::Test
  Sanitizer = Payment::SDK::Infrastructure::Logging::Sanitizer

  def test_sanitize_headers_redacts_sensitive_headers
    headers = {
      "Authorization" => "Bearer sk_test_secret_12345",
      "X-Api-Key" => "api_key_abcdef",
      "Signature" => "t=123,v1=sig_hash",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }

    sanitized = Sanitizer.sanitize_headers(headers)

    assert_equal "[FILTERED]", sanitized["Authorization"]
    assert_equal "[FILTERED]", sanitized["X-Api-Key"]
    assert_equal "[FILTERED]", sanitized["Signature"]
    assert_equal "application/json", sanitized["Content-Type"]
    assert_equal "application/json", sanitized["Accept"]
  end

  def test_sanitize_headers_handles_empty_or_nil
    assert_equal({}, Sanitizer.sanitize_headers({}))
    assert_equal({}, Sanitizer.sanitize_headers(nil))
  end

  def test_sanitize_url_redacts_sensitive_query_parameters
    url = "https://api.payment.com/v1/payment_intents?api_key=secret123&page=1&secret=topsecret"
    sanitized = Sanitizer.sanitize_url(url)

    assert_includes sanitized, "api_key=%5BFILTERED%5D"
    assert_includes sanitized, "secret=%5BFILTERED%5D"
    assert_includes sanitized, "page=1"
    refute_includes sanitized, "secret123"
    refute_includes sanitized, "topsecret"
  end

  def test_sanitize_url_leaves_urls_without_query_params_intact
    url = "https://api.payment.com/v1/payment_intents/pi_123"
    assert_equal url, Sanitizer.sanitize_url(url)
    assert_nil Sanitizer.sanitize_url(nil)
  end

  def test_sanitize_payload_redacts_nested_sensitive_keys
    payload = {
      amount: 1000,
      currency: "usd",
      payment_method_token: "pm_token_secret_999",
      metadata: {
        cvv: "123",
        notes: "order notes"
      },
      items: [
        {name: "book", card_number: "411111111111"}
      ]
    }

    sanitized = Sanitizer.sanitize_payload(payload)

    assert_equal 1000, sanitized[:amount]
    assert_equal "usd", sanitized[:currency]
    assert_equal "[FILTERED]", sanitized[:payment_method_token]
    assert_equal "[FILTERED]", sanitized[:metadata][:cvv]
    assert_equal "order notes", sanitized[:metadata][:notes]
    assert_equal "[FILTERED]", sanitized[:items].first[:card_number]
    assert_equal "book", sanitized[:items].first[:name]
  end
end
