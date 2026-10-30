# frozen_string_literal: true

require "test_helper"
require "payment/sdk/shared/application/base_command"

class SharedApplicationBaseCommandTest < Minitest::Test
  class DummyCommand < Payment::SDK::Shared::Application::BaseCommand
    def call(idempotency_key: nil)
      key = normalize_idempotency_key(idempotency_key)
      {key: key.value}
    end
  end

  class UnimplementedCommand < Payment::SDK::Shared::Application::BaseCommand
  end

  def setup
    @http_client = Object.new
    @cmd = DummyCommand.new(@http_client)
  end

  def test_subclass_must_implement_call
    unimplemented = UnimplementedCommand.new(@http_client)
    assert_raises(NotImplementedError) do
      unimplemented.call
    end
  end

  def test_normalize_idempotency_key_requires_key
    assert_raises(ArgumentError) { @cmd.call(idempotency_key: nil) }
    assert_raises(ArgumentError) { @cmd.call(idempotency_key: "") }
    assert_raises(ArgumentError) { @cmd.call(idempotency_key: "   ") }
  end

  def test_normalize_idempotency_key_with_string_and_value_object
    result = @cmd.call(idempotency_key: "custom-key")
    assert_equal "custom-key", result[:key]

    vo_key = Payment::SDK::Shared::Domain::ValueObjects::IdempotencyKey.new("vo-key")
    result_vo = @cmd.call(idempotency_key: vo_key)
    assert_equal "vo-key", result_vo[:key]
  end
end
