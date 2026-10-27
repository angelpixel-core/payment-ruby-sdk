# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/webhooks/ports/signature/verifier"

class DomainWebhooksPortsSignatureVerifierTest < Minitest::Test
  class DummyVerifier
    include Payment::SDK::Domain::Webhooks::Ports::Signature::Verifier
  end

  def test_raises_not_implemented
    verifier = DummyVerifier.new
    assert_raises(NotImplementedError) do
      verifier.verify(payload: "{}", signature: "sig", secret: "sec")
    end
  end
end
