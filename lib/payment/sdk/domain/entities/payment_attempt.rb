# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Entities
        class PaymentAttempt
          attr_reader :id, :payment_intent_id, :status, :payment_method_type, :error_code, :created_at

          def initialize(id:, payment_intent_id:, status:, payment_method_type:, error_code: nil, created_at:)
            @id = id.to_s
            @payment_intent_id = payment_intent_id.to_s
            @status = status.to_s
            @payment_method_type = payment_method_type.to_s
            @error_code = error_code&.to_s
            @created_at = created_at
            freeze
          end

          def failed?
            @status == "failed"
          end

          def succeeded?
            @status == "succeeded"
          end

          def requires_action?
            @status == "requires_action"
          end
        end
      end
    end
  end
end
