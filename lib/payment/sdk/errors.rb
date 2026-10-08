# frozen_string_literal: true

module Payment
  module SDK
    class Error < StandardError; end

    class ConfigurationError < Error; end
    class NetworkError < Error; end
    class TimeoutError < Error; end
    class SignatureVerificationError < Error; end

    class ApiError < Error
      attr_reader :status_code, :code, :details, :request_id, :raw_body

      def initialize(message, status_code: nil, code: nil, details: nil, request_id: nil, raw_body: nil)
        super(message)
        @status_code = status_code
        @code = code
        @details = details
        @request_id = request_id
        @raw_body = raw_body
      end
    end

    class InvalidRequestError < ApiError; end
    class PaymentNotFoundError < ApiError; end
    class PaymentDeclinedError < ApiError; end
    class DuplicateRequestError < ApiError; end
    class UpstreamError < ApiError; end
  end
end
