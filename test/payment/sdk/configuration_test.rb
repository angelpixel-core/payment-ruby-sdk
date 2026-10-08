# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    Payment::SDK.reset_configuration!
  end

  def teardown
    Payment::SDK.reset_configuration!
  end

  def test_has_a_version_number
    refute_nil Payment::SDK::VERSION
    assert_equal "0.1.0", Payment::SDK::VERSION
  end

  def test_default_configuration_values
    config = Payment::SDK.configuration

    assert_nil config.base_url
    assert_equal "v1", config.api_version
    assert_nil config.signing_secret
    assert_equal 10, config.timeout
    assert_equal 5, config.open_timeout
    assert_equal 2, config.max_retries
    assert_nil config.logger
  end

  def test_configure_via_block
    Payment::SDK.configure do |c|
      c.base_url = "http://localhost:10201"
      c.api_version = "v1"
      c.signing_secret = "secret_key_123"
      c.timeout = 15
      c.open_timeout = 3
      c.max_retries = 3
    end

    config = Payment::SDK.configuration
    assert_equal "http://localhost:10201", config.base_url
    assert_equal "v1", config.api_version
    assert_equal "secret_key_123", config.signing_secret
    assert_equal 15, config.timeout
    assert_equal 3, config.open_timeout
    assert_equal 3, config.max_retries
  end

  def test_reset_configuration
    Payment::SDK.configure do |c|
      c.base_url = "http://example.com"
      c.timeout = 30
    end

    Payment::SDK.reset_configuration!
    config = Payment::SDK.configuration

    assert_nil config.base_url
    assert_equal 10, config.timeout
  end

  def test_invalid_timeout_raises_argument_error
    assert_raises(ArgumentError) do
      Payment::SDK.configure do |c|
        c.timeout = -1
      end
    end
  end

  def test_invalid_max_retries_raises_argument_error
    assert_raises(ArgumentError) do
      Payment::SDK.configure do |c|
        c.max_retries = -5
      end
    end
  end
end
