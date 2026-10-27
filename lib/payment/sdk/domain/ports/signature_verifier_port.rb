# frozen_string_literal: true

require "payment/sdk/domain/webhooks/ports/signature/verifier"

module Payment
  module SDK
    module Domain
      module Ports
        SignatureVerifierPort = Payment::SDK::Domain::Webhooks::Ports::Signature::Verifier
      end
    end
  end
end
