# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/persistence/in_memory_inbox_store"
require "payment/sdk/application/use_cases/process_webhook"
require "payment/sdk/errors"

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

class InboxTest < Minitest::Test
  def setup
    @store = Payment::SDK::Infrastructure::Persistence::InMemoryInboxStore.new
    @verifier = MockVerifier.new(valid: true)
    @projection = MockProjection.new
    @use_case = Payment::SDK::Application::UseCases::ProcessWebhook.new(
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

    # Verify state in store
    stored = @store.find_by_delivery_id(@delivery_id)
    assert_equal :processed, stored[:status]
  end

  def test_duplicate_delivery_id_same_payload
    @use_case.call(
      delivery_id: @delivery_id,
      raw_payload: @payload,
      signature_header: @signature,
      secret: @secret
    )
    
    # Second call
    result = @use_case.call(
      delivery_id: @delivery_id,
      raw_payload: @payload,
      signature_header: @signature,
      secret: @secret
    )

    assert_equal :duplicate, result[:status]
  end

  def test_duplicate_delivery_id_different_payload
    @use_case.call(
      delivery_id: @delivery_id,
      raw_payload: @payload,
      signature_header: @signature,
      secret: @secret
    )
    
    # Second call with different payload
    assert_raises(ArgumentError, "delivery_id payload conflict") do
      @use_case.call(
        delivery_id: @delivery_id,
        raw_payload: "different",
        signature_header: @signature,
        secret: @secret
      )
    end
  end

  def test_invalid_signature
    failing_verifier = MockVerifier.new(valid: false)
    use_case = Payment::SDK::Application::UseCases::ProcessWebhook.new(
      inbox_store: @store,
      projection: @projection,
      verifier: failing_verifier
    )

    assert_raises(Payment::SDK::SignatureVerificationError) do
      use_case.call(
        delivery_id: @delivery_id,
        raw_payload: @payload,
        signature_header: @signature,
        secret: @secret
      )
    end

    stored = @store.find_by_delivery_id(@delivery_id)
    assert_equal :rejected_signature, stored[:status]
    refute @projection.applied
  end

  def test_projection_failure
    failing_projection = MockProjection.new(should_fail: true)
    use_case = Payment::SDK::Application::UseCases::ProcessWebhook.new(
      inbox_store: @store,
      projection: failing_projection,
      verifier: @verifier
    )

    assert_raises(StandardError, "Projection failed") do
      use_case.call(
        delivery_id: @delivery_id,
        raw_payload: @payload,
        signature_header: @signature,
        secret: @secret
      )
    end

    stored = @store.find_by_delivery_id(@delivery_id)
    assert_equal :failed, stored[:status]
    assert_equal "Projection failed", stored[:failure_reason]
  end
end
