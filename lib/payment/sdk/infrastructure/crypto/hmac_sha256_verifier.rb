# frozen_string_literal: true

require "payment/sdk/infrastructure/adapters/crypto/signature/verifier/hmac_sha256"

module Payment
  module SDK
    module Infrastructure
      module Crypto
        HmacSha256Verifier = Payment::SDK::Infrastructure::Adapters::Crypto::Signature::Verifier::HmacSha256
      end
    end
  end
end
