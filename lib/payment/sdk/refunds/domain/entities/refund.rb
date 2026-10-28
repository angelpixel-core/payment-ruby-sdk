# frozen_string_literal: true

module Payment
  module SDK
    # Refunds bounded context (partial and full charge refunds).
    module Refunds
      # Domain layer of the refunds bounded context.
      module Domain
        # Domain entities of the refunds bounded context.
        module Entities
          # Immutable domain entity representing a refund issued against a charge.
          class Refund
            # @return [String] unique refund identifier (`re_...`)
            attr_reader :id
            # @return [String] charge identifier (`ch_...`)
            attr_reader :charge_id
            # @return [Integer] refunded amount in minor currency units
            attr_reader :amount
            # @return [Symbol] normalized refund status (`:succeeded`, `:failed`, `:pending`)
            attr_reader :status
            # @return [String, nil] optional refund reason
            attr_reader :reason
            # @return [String, nil] 3-letter ISO currency code
            attr_reader :currency
            # @return [String, Time, nil] creation timestamp
            attr_reader :created_at

            # @param id [String] refund identifier
            # @param charge_id [String] parent charge identifier
            # @param amount [Integer] refunded amount in minor units
            # @param status [String, Symbol] refund status (normalized to `Symbol`)
            # @param reason [String, nil] optional refund reason
            # @param currency [String, nil] optional currency code
            # @param created_at [String, Time, nil] optional creation timestamp
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

            # @return [Boolean] `true` when status is `:succeeded`
            def succeeded?
              @status == :succeeded
            end

            # @return [Boolean] `true` when status is `:failed`
            def failed?
              @status == :failed
            end

            # @return [Boolean] `true` when status is `:pending`
            def pending?
              @status == :pending
            end
          end
        end
      end
    end
  end
end
