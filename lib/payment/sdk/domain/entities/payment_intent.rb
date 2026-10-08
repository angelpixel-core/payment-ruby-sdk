# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Entities
        class PaymentIntent
          attr_reader :id, :amount, :currency, :status, :customer_id, :merchant_id,
                      :capture_method, :latest_attempt_id, :charge_id

          def initialize(id:, amount:, currency:, status:, customer_id:, merchant_id:,
                         capture_method:, latest_attempt_id: nil, charge_id: nil)
            @id = id.to_s
            @amount = amount.to_i
            @currency = currency.to_s
            @status = status.to_s
            @customer_id = customer_id.to_s
            @merchant_id = merchant_id.to_s
            @capture_method = capture_method.to_s
            @latest_attempt_id = latest_attempt_id&.to_s
            @charge_id = charge_id&.to_s
            freeze
          end

          def succeeded?
            @status == "succeeded"
          end

          def canceled?
            @status == "canceled"
          end

          def requires_capture?
            @status == "requires_capture"
          end

          def requires_payment_method?
            @status == "requires_payment_method"
          end

          def requires_action?
            @status == "requires_action"
          end

          def processing?
            @status == "processing"
          end

          def requires_confirmation?
            @status == "requires_confirmation"
          end
        end
      end
    end
  end
end
