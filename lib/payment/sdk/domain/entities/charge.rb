# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Entities
        class Charge
          attr_reader :id, :payment_intent_id, :amount, :captured_amount, :refunded_amount, :status

          def initialize(id:, payment_intent_id:, amount:, captured_amount: 0, refunded_amount: 0, status:)
            @id = id.to_s
            @payment_intent_id = payment_intent_id.to_s
            @amount = amount.to_i
            @captured_amount = captured_amount.to_i
            @refunded_amount = refunded_amount.to_i
            @status = status.to_s
            freeze
          end

          def succeeded?
            @status == "succeeded"
          end

          def failed?
            @status == "failed"
          end

          def pending?
            @status == "pending"
          end

          def fully_captured?
            succeeded? && @captured_amount == @amount
          end

          def partially_captured?
            succeeded? && @captured_amount > 0 && @captured_amount < @amount
          end

          def uncaptured?
            succeeded? && @captured_amount == 0
          end

          def fully_refunded?
            @refunded_amount == @amount
          end

          def partially_refunded?
            @refunded_amount > 0 && @refunded_amount < @amount
          end
        end
      end
    end
  end
end
