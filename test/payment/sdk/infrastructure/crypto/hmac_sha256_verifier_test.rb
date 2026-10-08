# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/crypto/hmac_sha256_verifier"

class HmacSha256VerifierTest < Minitest::Test
  def setup
    @verifier = Payment::SDK::Infrastructure::Crypto::HmacSha256Verifier.new
    @secret = "whsec_test_secret"
    @payload = '{"event_id":"evt_123"}'
  end

  def test_verify_valid_signature
    timestamp = Time.now.to_i
    signed_payload = "#{timestamp}.#{@payload}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", @secret, signed_payload)
    
    header = "t=#{timestamp},v1=#{signature}"

    assert @verifier.verify(payload: @payload, signature: header, secret: @secret)
  end

  def test_verify_invalid_signature
    timestamp = Time.now.to_i
    header = "t=#{timestamp},v1=invalid_signature"

    assert_raises(Payment::SDK::SignatureVerificationError) do
      @verifier.verify(payload: @payload, signature: header, secret: @secret)
    end
  end

  def test_verify_expired_timestamp
    timestamp = Time.now.to_i - 600 # 10 minutes ago
    signed_payload = "#{timestamp}.#{@payload}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", @secret, signed_payload)
    
    header = "t=#{timestamp},v1=#{signature}"

    assert_raises(Payment::SDK::SignatureVerificationError) do
      @verifier.verify(payload: @payload, signature: header, secret: @secret, timestamp_tolerance: 300)
    end
  end

  def test_verify_missing_elements
    timestamp = Time.now.to_i
    
    assert_raises(Payment::SDK::SignatureVerificationError) do
      @verifier.verify(payload: @payload, signature: "t=#{timestamp}", secret: @secret)
    end

    assert_raises(Payment::SDK::SignatureVerificationError) do
      @verifier.verify(payload: @payload, signature: "v1=something", secret: @secret)
    end
  end

  def test_verify_missing_arguments
    assert_raises(Payment::SDK::SignatureVerificationError) do
      @verifier.verify(payload: nil, signature: "sig", secret: @secret)
    end

    assert_raises(Payment::SDK::SignatureVerificationError) do
      @verifier.verify(payload: @payload, signature: nil, secret: @secret)
    end

    assert_raises(Payment::SDK::SignatureVerificationError) do
      @verifier.verify(payload: @payload, signature: "sig", secret: nil)
    end
  end
end
