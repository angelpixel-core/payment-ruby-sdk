# frozen_string_literal: true

module Payment
  module SDK
    module Payments
      module Domain
        module Entities
          # Immutable domain entity representing a charge associated with a {PaymentIntent}.
          class Charge
            # @return [String] unique charge identifier (`ch_...`)
            attr_reader :id
            # @return [String] parent payment intent identifier (`pi_...`)
            attr_reader :payment_intent_id
            # @return [Integer] authorized charge amount in minor units
            attr_reader :amount
            # @return [Integer] captured amount in minor units
            attr_reader :captured_amount
            # @return [Symbol] normalized charge status symbol
            attr_reader :status
            # @return [String, nil] 3-letter ISO currency code
            attr_reader :currency
            # @return [String, Time, nil] creation timestamp
            attr_reader :created_at

            # @param id [String] charge identifier
            # @param payment_intent_id [String] parent payment intent identifier
            # @param amount [Integer] authorized amount in minor units
            # @param captured_amount [Integer] captured amount in minor units
            # @param status [String, Symbol] charge status (normalized to `Symbol`)
            # @param currency [String, nil] optional currency code
            # @param created_at [String, Time, nil] optional creation timestamp
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

            # @return [Boolean] `true` when status is `:succeeded`
            def succeeded?
              @status == :succeeded
            end

            # @return [Boolean] `true` when {#captured_amount} is positive and less than {#amount}
            def partially_captured?
              @captured_amount > 0 && @captured_amount < @amount
            end

            # @return [Boolean] `true` when {#captured_amount} is greater than or equal to {#amount}
            def fully_captured?
              @captured_amount >= @amount
            end
          end
        end
      end
    end
  end
end
