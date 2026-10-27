# frozen_string_literal: true

require "test_helper"
require "payment/sdk/webhooks/domain/ports/signature/verifier"

class WebhooksDomainPortsSignatureVerifierTest < Minitest::Test
  class UnimplementedVerifier
    include Payment::SDK::Webhooks::Domain::Ports::Signature::Verifier
  end

  def setup
    @verifier = UnimplementedVerifier.new
  end

  def test_verify_raises_not_implemented
    assert_raises(NotImplementedError) do
      @verifier.verify(payload: "{}", signature: "sig", secret: "sec")
    end
  end
end
