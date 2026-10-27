# frozen_string_literal: true

require "test_helper"
require "payment/sdk/webhooks/application/use_cases/process"
require "payment/sdk/infrastructure/adapters/persistence/inbox/store/in_memory"
require "payment/sdk/errors"

class WebhooksApplicationUseCasesProcessTest < Minitest::Test
  class MockVerifier
    attr_accessor :valid

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
    @use_case = Payment::SDK::Webhooks::Application::UseCases::Process.new(
      inbox_store: @store,
      projection: @projection,
      verifier: @verifier
    )
  end

  def test_successful_processing
    result = @use_case.call(
      delivery_id: "del_1",
      raw_payload: '{"event":"ok"}',
      signature_header: "sig",
      secret: "sec"
    )

    assert_equal :processed, result[:status]
    assert @projection.applied
    assert_equal :processed, @store.find_by_delivery_id("del_1")[:status]
  end

  def test_duplicate_delivery_id_same_payload
    @use_case.call(
      delivery_id: "del_1",
      raw_payload: '{"event":"ok"}',
      signature_header: "sig",
      secret: "sec"
    )

    dup_result = @use_case.call(
      delivery_id: "del_1",
      raw_payload: '{"event":"ok"}',
      signature_header: "sig",
      secret: "sec"
    )

    assert_equal :duplicate, dup_result[:status]
  end

  def test_duplicate_delivery_id_conflicting_payload
    @use_case.call(
      delivery_id: "del_1",
      raw_payload: '{"event":"ok"}',
      signature_header: "sig",
      secret: "sec"
    )

    assert_raises(ArgumentError) do
      @use_case.call(
        delivery_id: "del_1",
        raw_payload: '{"event":"conflict"}',
        signature_header: "sig",
        secret: "sec"
      )
    end
  end

  def test_invalid_signature_records_rejected_status
    @verifier.valid = false

    assert_raises(Payment::SDK::SignatureVerificationError) do
      @use_case.call(
        delivery_id: "del_2",
        raw_payload: '{"event":"ok"}',
        signature_header: "sig",
        secret: "sec"
      )
    end

    assert_equal :rejected_signature, @store.find_by_delivery_id("del_2")[:status]
  end
end
