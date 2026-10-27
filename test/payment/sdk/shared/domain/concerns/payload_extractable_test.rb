# frozen_string_literal: true

require "test_helper"
require "payment/sdk/shared/domain/concerns/payload_extractable"

class SharedDomainConcernsPayloadExtractableTest < Minitest::Test
  class DummyHost
    include Payment::SDK::Shared::Domain::Concerns::PayloadExtractable

    attr_reader :data

    def initialize(data)
      @data = data
    end
  end

  def test_extract_prefixed_id_from_nested_object_with_symbol_keys
    host = DummyHost.new(object: { id: "pi_12345" })
    assert_equal "pi_12345", host.extract_prefixed_id("pi_", :payment_intent_id)
  end

  def test_extract_prefixed_id_from_nested_object_with_string_keys
    host = DummyHost.new("object" => { "id" => "ch_999" })
    assert_equal "ch_999", host.extract_prefixed_id("ch_", :charge_id)
  end

  def test_extract_prefixed_id_fallback_to_root_key
    host = DummyHost.new(refund_id: "re_root_123")
    assert_equal "re_root_123", host.extract_prefixed_id("re_", :refund_id)
  end

  def test_returns_nil_when_data_is_not_hash_or_missing
    host_nil = DummyHost.new(nil)
    assert_nil host_nil.extract_prefixed_id("pi_", :payment_intent_id)

    host_string = DummyHost.new("not a hash")
    assert_nil host_string.extract_prefixed_id("pi_", :payment_intent_id)
  end

  def test_returns_nil_when_prefix_does_not_match
    host = DummyHost.new(object: { id: "cus_999" })
    assert_nil host.extract_prefixed_id("pi_", :payment_intent_id)
  end
end
