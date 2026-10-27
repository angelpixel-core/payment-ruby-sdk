# frozen_string_literal: true

module Payment
  module SDK
    module Refunds
      module Domain
        module Entities
          class Refund
            attr_reader :id, :charge_id, :amount, :status, :reason, :currency, :created_at

            def initialize(id:, charge_id:, amount:, status:, reason: nil, currency: nil, created_at: nil)
              @id = id
              @charge_id = charge_id
              @amount = amount
              @status = status.to_sym
              @reason = reason
              @currency = currency
              @created_at = created_at
              freeze
            end

            def succeeded?
              @status == :succeeded
            end

            def failed?
              @status == :failed
            end

            def pending?
              @status == :pending
            end
          end
        end
      end
    end
  end
end
