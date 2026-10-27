# frozen_string_literal: true

module Payment
  module SDK
    module Payments
      module Domain
        module Entities
          class PaymentAttempt
            attr_reader :id, :payment_intent_id, :status, :payment_method_type,
                        :error_code, :error_message, :created_at

            def initialize(id:, payment_intent_id:, status:, payment_method_type:,
                           error_code: nil, error_message: nil, created_at: nil)
              @id = id
              @payment_intent_id = payment_intent_id
              @status = status.to_sym
              @payment_method_type = payment_method_type
              @error_code = error_code
              @error_message = error_message
              @created_at = created_at
              freeze
            end

            def successful?
              @status == :successful || @status == :succeeded
            end
            alias_method :succeeded?, :successful?

            def failed?
              @status == :failed
            end
          end
        end
      end
    end
  end
end
