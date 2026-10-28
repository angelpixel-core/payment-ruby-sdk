# frozen_string_literal: true

module Payment
  module SDK
    module Webhooks
      module Domain
        module Ports
          # Cryptographic signature verification port namespace.
          module Signature
            # Secondary port defining the contract for verifying incoming webhook signatures.
            module Verifier
              # Verifies the authenticity and timestamp freshness of a webhook payload.
              #
              # @param payload [String] raw webhook request body
              # @param signature [String] signature header value (`t=...,v1=...`)
              # @param secret [String] shared webhook signing secret
              # @param timestamp_tolerance [Integer] maximum allowed clock skew in seconds
              # @return [Boolean] `true` when the signature is valid
              # @raise [NotImplementedError] when not implemented by an adapter
              def verify(payload:, signature:, secret:, timestamp_tolerance: 300)
                raise NotImplementedError, "#{self.class} must implement #verify"
              end
            end
          end
        end
      end
    end
  end
end
