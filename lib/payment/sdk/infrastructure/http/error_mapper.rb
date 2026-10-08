# frozen_string_literal: true

require "payment/sdk/errors"
require "json"

module Payment
  module SDK
    module Infrastructure
      module Http
        class ErrorMapper
          def self.map_error(response, request_id: nil)
            status_code = response.code.to_i
            raw_body = response.body

            return if status_code >= 200 && status_code < 300

            begin
              parsed_body = JSON.parse(raw_body)
              error_code = parsed_body["error_code"] || parsed_body["code"]
              message = parsed_body["message"] || "API Error"
              details = parsed_body["details"]
            rescue JSON::ParserError
              error_code = "unknown_error"
              message = "Received non-JSON response from API"
              details = nil
            end

            error_class = determine_error_class(status_code, error_code)
            
            raise error_class.new(
              message,
              status_code: status_code,
              code: error_code,
              details: details,
              request_id: request_id,
              raw_body: raw_body
            )
          end

          private_class_method def self.determine_error_class(status_code, error_code)
            case error_code
            when "invalid_amount", "invalid_currency", "missing_idempotency_key", "invalid_intent_state"
              Payment::SDK::InvalidRequestError
            when "payment_intent_not_found", "charge_not_found", "refund_not_found"
              Payment::SDK::PaymentNotFoundError
            when "idempotency_conflict"
              Payment::SDK::DuplicateRequestError
            when "invalid_scenario", "payment_declined"
              Payment::SDK::PaymentDeclinedError
            when "internal_error", "panic"
              Payment::SDK::UpstreamError
            else
              if status_code >= 500
                Payment::SDK::UpstreamError
              elsif status_code == 404
                Payment::SDK::PaymentNotFoundError
              elsif status_code == 409
                Payment::SDK::DuplicateRequestError
              elsif status_code >= 400 && status_code < 500
                Payment::SDK::InvalidRequestError
              else
                Payment::SDK::ApiError
              end
            end
          end
        end
      end
    end
  end
end
