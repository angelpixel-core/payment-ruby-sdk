# frozen_string_literal: true

require "test_helper"
require "payment/sdk/application/shared/base_command"

class SharedBaseCommandTest < Minitest::Test
  class TestCommand < Payment::SDK::Application::Shared::BaseCommand
    def execute(key)
      default_headers(key)
    end
  end

  def test_base_command_initialization
    client = Object.new
    cmd = TestCommand.new(client)
    assert_equal client, cmd.http_client
  end

  def test_base_command_idempotency_key_validation
    cmd = TestCommand.new(Object.new)
    assert_raises(ArgumentError) { cmd.execute(nil) }
    assert_raises(ArgumentError) { cmd.execute("   ") }
  end

  def test_base_command_headers_generation
    cmd = TestCommand.new(Object.new)
    headers = cmd.execute("my-idemp-key")
    assert_equal({ "Idempotency-Key" => "my-idemp-key" }, headers)
  end
end
