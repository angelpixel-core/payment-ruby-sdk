# frozen_string_literal: true

module Payment
  module SDK
    module Payments
      module Domain
        module Entities
          class Charge
            attr_reader :id, :payment_intent_id, :amount, :captured_amount,
                        :status, :currency, :created_at

            def initialize(id:, payment_intent_id:, amount:, captured_amount:, status:,
                           currency: nil, created_at: nil)
              @id = id
              @payment_intent_id = payment_intent_id
              @amount = amount
              @captured_amount = captured_amount
              @status = status.to_sym
              @currency = currency
              @created_at = created_at
              freeze
            end

            def succeeded?
              @status == :succeeded
            end

            def partially_captured?
              @captured_amount > 0 && @captured_amount < @amount
            end

            def fully_captured?
              @captured_amount >= @amount
            end
          end
        end
      end
    end
  end
end
