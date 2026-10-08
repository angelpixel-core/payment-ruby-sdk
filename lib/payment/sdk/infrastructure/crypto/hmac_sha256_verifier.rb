# frozen_string_literal: true

require "openssl"
require "payment/sdk/domain/ports/signature_verifier_port"
require "payment/sdk/errors"

module Payment
  module SDK
    module Infrastructure
      module Crypto
        class HmacSha256Verifier
          include Payment::SDK::Domain::Ports::SignatureVerifierPort

          def verify(payload:, signature:, secret:, timestamp_tolerance: 300)
            raise Payment::SDK::SignatureVerificationError, "Missing signature" if signature.nil? || signature.to_s.strip.empty?
            raise Payment::SDK::SignatureVerificationError, "Missing payload" if payload.nil?
            raise Payment::SDK::SignatureVerificationError, "Missing secret" if secret.nil? || secret.to_s.strip.empty?

            # Format of signature header: t=1492774577,v1=5257a869e7ecebeda32affa62cdca3fa51cad7e77a0e56ff536d0ce8e108d8bd
            elements = signature.split(",")
            timestamp_str = elements.find { |e| e.start_with?("t=") }&.sub("t=", "")
            signature_v1 = elements.find { |e| e.start_with?("v1=") }&.sub("v1=", "")

            raise Payment::SDK::SignatureVerificationError, "Invalid signature format" unless timestamp_str && signature_v1

            timestamp = timestamp_str.to_i
            verify_timestamp!(timestamp, timestamp_tolerance)

            expected_sig = compute_signature(payload, timestamp, secret)

            unless secure_compare(expected_sig, signature_v1)
              raise Payment::SDK::SignatureVerificationError, "Signature does not match"
            end

            true
          end

          private

          def verify_timestamp!(timestamp, tolerance)
            current_time = Time.now.to_i
            if (current_time - timestamp).abs > tolerance
              raise Payment::SDK::SignatureVerificationError, "Timestamp outside of tolerance limit"
            end
          end

          def compute_signature(payload, timestamp, secret)
            signed_payload = "#{timestamp}.#{payload}"
            OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
          end

          def secure_compare(a, b)
            return false unless a.bytesize == b.bytesize

            if OpenSSL.respond_to?(:fixed_length_secure_compare)
              OpenSSL.fixed_length_secure_compare(a, b)
            else
              # Fallback for constant-time comparison
              res = 0
              a.unpack("C*").zip(b.unpack("C*")) { |x, y| res |= x ^ y }
              res == 0
            end
          end
        end
      end
    end
  end
end
