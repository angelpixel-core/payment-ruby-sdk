# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Entities
        class Refund
          attr_reader :id, :charge_id, :amount, :status, :reason, :created_at

          def initialize(id:, charge_id:, amount:, status:, reason: nil, created_at:)
            @id = id.to_s
            @charge_id = charge_id.to_s
            @amount = amount.to_i
            @status = status.to_s
            @reason = reason&.to_s
            @created_at = created_at
            freeze
          end

          def succeeded?
            @status == "succeeded"
          end

          def pending?
            @status == "pending"
          end

          def failed?
            @status == "failed"
          end

          def canceled?
            @status == "canceled"
          end
        end
      end
    end
  end
end
