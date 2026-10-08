# frozen_string_literal: true

module Payment
  module SDK
    class Configuration
      DEFAULT_API_VERSION = "v1"
      DEFAULT_TIMEOUT = 10
      DEFAULT_OPEN_TIMEOUT = 5
      DEFAULT_MAX_RETRIES = 2

      attr_accessor :base_url, :api_version, :api_key, :signing_secret, :timeout,
                    :open_timeout, :max_retries, :logger

      def initialize
        @base_url = nil
        @api_version = DEFAULT_API_VERSION
        @api_key = nil
        @signing_secret = nil
        @timeout = DEFAULT_TIMEOUT
        @open_timeout = DEFAULT_OPEN_TIMEOUT
        @max_retries = DEFAULT_MAX_RETRIES
        @logger = nil
      end

      def dup
        copy = super
        copy
      end

      def validate!
        validate_timeouts!
        validate_retries!
      end

      private

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
    end
  end
end
