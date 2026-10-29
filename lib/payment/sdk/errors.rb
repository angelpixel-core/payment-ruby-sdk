# frozen_string_literal: true

require "payment/sdk/infrastructure/logging/sanitizer"

module Payment
  module SDK
    # Base error class for all exceptions raised by {Payment::SDK}.
    class Error < StandardError; end

    # Raised when the SDK configuration is missing or invalid.
    class ConfigurationError < Error; end

    # Raised when an underlying socket or transport error occurs during an HTTP request.
    class NetworkError < Error; end

    # Raised when an HTTP connection or read operation exceeds the configured timeout.
    class TimeoutError < Error; end

    # Raised when a webhook signature header is missing, malformed, expired, or invalid.
    class SignatureVerificationError < Error; end

    # Raised when the circuit breaker is in OPEN state and upstream requests are paused.
    class CircuitBreakerOpenError < Error
      # @return [Numeric, nil] timeout in seconds before probing the upstream in HALF_OPEN state
      attr_reader :reset_timeout
      # @return [Symbol] current state of the circuit breaker (`:open`)
      attr_reader :state

      # @param message [String] error description
      # @param reset_timeout [Numeric, nil] duration before half-open probe
      # @param state [Symbol] circuit state
      def initialize(message = "Circuit breaker is OPEN. Upstream requests are temporarily paused.", reset_timeout: nil, state: :open)
        super(message)
        @reset_timeout = reset_timeout
        @state = state
      end
    end

    # Base error class for non-2xx HTTP responses returned by the payment platform API.
    class ApiError < Error
      # @return [Integer, nil] HTTP status code returned by the server
      attr_reader :status_code
      # @return [String, nil] machine-readable error code returned by the API
      attr_reader :code
      # @return [Object, nil] additional error details from the response payload (sanitized)
      attr_reader :details
      # @return [String, nil] upstream request identifier if available
      attr_reader :request_id
      # @return [String, nil] unparsed HTTP response body (sanitized)
      attr_reader :raw_body

      # @param message [String] human-readable error description
      # @param status_code [Integer, nil] HTTP status code
      # @param code [String, nil] machine-readable API error code
      # @param details [Object, nil] structured error details
      # @param request_id [String, nil] request correlation identifier
      # @param raw_body [String, nil] raw HTTP response body
      def initialize(message, status_code: nil, code: nil, details: nil, request_id: nil, raw_body: nil)
        super(message)
        @status_code = status_code
        @code = code
        @details = sanitize_details(details)
        @request_id = request_id
        @raw_body = sanitize_body(raw_body)
      end

      private

      def sanitize_details(details)
        Infrastructure::Logging::Sanitizer.sanitize_payload(details)
      rescue NameError
        details
      end

      def sanitize_body(raw_body)
        Infrastructure::Logging::Sanitizer.sanitize_raw_body(raw_body)
      rescue NameError
        raw_body
      end
    end

    # Raised on HTTP 4xx validation errors or invalid request parameters/state.
    class InvalidRequestError < ApiError; end

    # Raised on HTTP 404 or when a payment intent, charge, or refund is not found.
    class PaymentNotFoundError < ApiError; end

    # Raised when a payment attempt is declined or an invalid sandbox scenario is supplied.
    class PaymentDeclinedError < ApiError; end

    # Raised on HTTP 409 or idempotency key conflict.
    class DuplicateRequestError < ApiError; end

    # Raised on HTTP 429 when the rate limit has been exceeded.
    class RateLimitError < ApiError
      # @return [Integer, nil] number of seconds to wait before retrying, if provided by the upstream
      attr_reader :retry_after_seconds

      # @param message [String] error description
      # @param status_code [Integer, nil] HTTP status code (defaults to 429)
      # @param code [String, nil] API error code
      # @param details [Object, nil] structured details
      # @param request_id [String, nil] correlation identifier
      # @param raw_body [String, nil] raw response body
      # @param retry_after_seconds [Integer, nil] delay in seconds suggested by Retry-After header
      def initialize(message, status_code: 429, code: nil, details: nil, request_id: nil, raw_body: nil, retry_after_seconds: nil)
        super(message, status_code: status_code, code: code, details: details, request_id: request_id, raw_body: raw_body)
        @retry_after_seconds = retry_after_seconds
      end
    end

    # Raised on HTTP 5xx or upstream internal server errors.
    class UpstreamError < ApiError; end
  end
end
