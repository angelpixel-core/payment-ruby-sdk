# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/crypto/signature/verifier/hmac_sha256"
require "payment/sdk/errors"

class InfrastructureAdaptersCryptoSignatureVerifierHmacSha256Test < Minitest::Test
  def setup
    @verifier = Payment::SDK::Infrastructure::Adapters::Crypto::Signature::Verifier::HmacSha256.new
    @secret = "whsec_test_secret_123"
    @payload = '{"id":"evt_123","type":"payment_intent.succeeded"}'
  end

  def test_successful_verification
    timestamp = Time.now.to_i
    signed_payload = "#{timestamp}.#{@payload}"
    signature_hash = OpenSSL::HMAC.hexdigest("SHA256", @secret, signed_payload)
    header = "t=#{timestamp},v1=#{signature_hash}"

    assert @verifier.verify(payload: @payload, signature: header, secret: @secret)
  end

  def test_fails_with_invalid_signature
    timestamp = Time.now.to_i
    header = "t=#{timestamp},v1=invalid_signature_hex_1234567890abcdef"

    assert_raises(Payment::SDK::SignatureVerificationError) do
      @verifier.verify(payload: @payload, signature: header, secret: @secret)
    end
  end

  def test_fails_with_expired_timestamp
    timestamp = Time.now.to_i - 400
    signed_payload = "#{timestamp}.#{@payload}"
    signature_hash = OpenSSL::HMAC.hexdigest("SHA256", @secret, signed_payload)
    header = "t=#{timestamp},v1=#{signature_hash}"

    assert_raises(Payment::SDK::SignatureVerificationError) do
      @verifier.verify(payload: @payload, signature: header, secret: @secret, timestamp_tolerance: 300)
    end
  end
end
