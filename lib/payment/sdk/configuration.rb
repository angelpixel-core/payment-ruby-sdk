# frozen_string_literal: true

module Payment
  module SDK
    # Holds runtime configuration for {Payment::SDK::Client} instances, including
    # API credentials, endpoint URL, HTTP timeouts, retry count, and optional logger.
    class Configuration
      # Default API version string.
      DEFAULT_API_VERSION = "v1"
      # Default HTTP read timeout in seconds.
      DEFAULT_TIMEOUT = 10
      # Default HTTP connection open timeout in seconds.
      DEFAULT_OPEN_TIMEOUT = 5
      # Default maximum number of automatic retries on transient errors.
      DEFAULT_MAX_RETRIES = 2
      # Default logging level.
      DEFAULT_LOG_LEVEL = :info
      # Supported logging levels.
      VALID_LOG_LEVELS = %i[debug info warn error fatal].freeze
      # Default circuit breaker enabled flag.
      DEFAULT_CIRCUIT_BREAKER_ENABLED = true
      # Default consecutive failures to trip circuit breaker.
      DEFAULT_CIRCUIT_BREAKER_FAILURE_THRESHOLD = 5
      # Default cooldown in seconds before half-open probe.
      DEFAULT_CIRCUIT_BREAKER_RESET_TIMEOUT = 30
      # Default maximum delay in seconds to wait for HTTP 429 Retry-After.
      DEFAULT_RATE_LIMIT_MAX_DELAY = 10

      # @return [String, nil] base URL of the payment platform API
      attr_accessor :base_url
      # @return [String] target API version (defaults to {DEFAULT_API_VERSION})
      attr_accessor :api_version
      # @return [String, nil] bearer API key used for authenticating HTTP requests
      attr_accessor :api_key
      # @return [String, nil] HMAC secret used for verifying incoming webhooks
      attr_accessor :signing_secret
      # @return [Numeric] HTTP read timeout in seconds (defaults to {DEFAULT_TIMEOUT})
      attr_accessor :timeout
      # @return [Numeric] HTTP open timeout in seconds (defaults to {DEFAULT_OPEN_TIMEOUT})
      attr_accessor :open_timeout
      # @return [Integer] maximum number of retries on network/timeout/5xx errors (defaults to {DEFAULT_MAX_RETRIES})
      attr_accessor :max_retries
      # @return [Object, nil] optional logger instance responding to `#info`, `#warn`, `#error`, `#debug`
      attr_accessor :logger
      # @return [Symbol, String] minimum logging severity level (defaults to {DEFAULT_LOG_LEVEL})
      attr_accessor :log_level
      # @return [Boolean] whether circuit breaker protection is active (defaults to {DEFAULT_CIRCUIT_BREAKER_ENABLED})
      attr_accessor :circuit_breaker_enabled
      # @return [Integer] consecutive failure count before tripping circuit (defaults to {DEFAULT_CIRCUIT_BREAKER_FAILURE_THRESHOLD})
      attr_accessor :circuit_breaker_failure_threshold
      # @return [Numeric] seconds to wait in open state before probing (defaults to {DEFAULT_CIRCUIT_BREAKER_RESET_TIMEOUT})
      attr_accessor :circuit_breaker_reset_timeout
      # @return [Numeric] maximum seconds to sleep on 429 Retry-After (defaults to {DEFAULT_RATE_LIMIT_MAX_DELAY})
      attr_accessor :rate_limit_max_delay

      # Initializes a new configuration with default timeouts, retry count, and API version.
      def initialize
        @base_url = nil
        @api_version = DEFAULT_API_VERSION
        @api_key = nil
        @signing_secret = nil
        @timeout = DEFAULT_TIMEOUT
        @open_timeout = DEFAULT_OPEN_TIMEOUT
        @max_retries = DEFAULT_MAX_RETRIES
        @logger = nil
        @log_level = DEFAULT_LOG_LEVEL
        @circuit_breaker_enabled = DEFAULT_CIRCUIT_BREAKER_ENABLED
        @circuit_breaker_failure_threshold = DEFAULT_CIRCUIT_BREAKER_FAILURE_THRESHOLD
        @circuit_breaker_reset_timeout = DEFAULT_CIRCUIT_BREAKER_RESET_TIMEOUT
        @rate_limit_max_delay = DEFAULT_RATE_LIMIT_MAX_DELAY
      end

      # Returns a shallow copy of the configuration.
      #
      # @return [Payment::SDK::Configuration]
      def dup
        super
      end

      # Validates numeric timeout and retry invariants.
      #
      # @return [void]
      # @raise [ArgumentError] when `timeout`, `open_timeout`, `max_retries`, or `log_level` is invalid
      def validate!
        validate_timeouts!
        validate_retries!
        validate_log_level!
        validate_resilience!
      end

      private

      def validate_resilience!
        if @circuit_breaker_failure_threshold && (!@circuit_breaker_failure_threshold.is_a?(Integer) || @circuit_breaker_failure_threshold <= 0)
          raise ArgumentError, "circuit_breaker_failure_threshold must be a positive integer"
        end

        if @circuit_breaker_reset_timeout && (!@circuit_breaker_reset_timeout.is_a?(Numeric) || @circuit_breaker_reset_timeout <= 0)
          raise ArgumentError, "circuit_breaker_reset_timeout must be a positive numeric value"
        end

        if @rate_limit_max_delay && (!@rate_limit_max_delay.is_a?(Numeric) || @rate_limit_max_delay <= 0)
          raise ArgumentError, "rate_limit_max_delay must be a positive numeric value"
        end
      end

      def validate_timeouts!
        if @timeout && (!@timeout.is_a?(Numeric) || @timeout <= 0)
          raise ArgumentError, "timeout must be a positive numeric value"
        end

        if @open_timeout && (!@open_timeout.is_a?(Numeric) || @open_timeout <= 0)
          raise ArgumentError, "open_timeout must be a positive numeric value"
        end
      end

      def validate_retries!
        if @max_retries && (!@max_retries.is_a?(Integer) || @max_retries.negative?)
          raise ArgumentError, "max_retries must be a non-negative integer"
        end
      end

      def validate_log_level!
        return if @log_level.nil?

        level = @log_level.to_s.downcase.to_sym
        unless VALID_LOG_LEVELS.include?(level)
          raise ArgumentError, "log_level must be one of #{VALID_LOG_LEVELS.inspect}, got #{@log_level.inspect}"
        end
      end
    end
  end
end
