# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/adapters/persistence/inbox/store/in_memory"
require "payment/sdk/application/webhooks/use_cases/process"
require "payment/sdk/errors"

class ApplicationWebhooksUseCasesProcessTest < Minitest::Test
  class MockVerifier
    def initialize(valid: true)
      @valid = valid
    end

    def verify(payload:, signature:, secret:, timestamp_tolerance: 300)
      raise Payment::SDK::SignatureVerificationError, "Invalid signature" unless @valid

      true
    end
  end

  class MockProjection
    attr_reader :applied

    def initialize(should_fail: false)
      @should_fail = should_fail
      @applied = false
    end

    def apply!(inbox_entry:)
      raise StandardError, "Projection failed" if @should_fail

      @applied = true
    end
  end

  def setup
    @store = Payment::SDK::Infrastructure::Adapters::Persistence::Inbox::Store::InMemory.new
    @verifier = MockVerifier.new(valid: true)
    @projection = MockProjection.new
    @use_case = Payment::SDK::Application::Webhooks::UseCases::Process.new(
      inbox_store: @store,
      projection: @projection,
      verifier: @verifier
    )
    @delivery_id = "del_123"
    @payload = '{"event":"payment_succeeded"}'
    @signature = "sig_123"
    @secret = "sec_123"
  end

  def test_successful_processing
    result = @use_case.call(
      delivery_id: @delivery_id,
      raw_payload: @payload,
      signature_header: @signature,
      secret: @secret
    )

    assert_equal :processed, result[:status]
    assert_equal :processed, result[:entry][:status]
    assert @projection.applied
  end

  def test_idempotent_duplicate_processing
    @use_case.call(
      delivery_id: @delivery_id,
      raw_payload: @payload,
      signature_header: @signature,
      secret: @secret
    )

    result2 = @use_case.call(
      delivery_id: @delivery_id,
      raw_payload: @payload,
      signature_header: @signature,
      secret: @secret
    )

    assert_equal :duplicate, result2[:status]
  end

  def test_payload_conflict_raises_error
    @use_case.call(
      delivery_id: @delivery_id,
      raw_payload: @payload,
      signature_header: @signature,
      secret: @secret
    )

    assert_raises(ArgumentError) do
      @use_case.call(
        delivery_id: @delivery_id,
        raw_payload: '{"event":"different"}',
        signature_header: @signature,
        secret: @secret
      )
    end
  end
end
