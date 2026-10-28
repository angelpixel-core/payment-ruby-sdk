# frozen_string_literal: true

require "payment/sdk/shared/domain/value_objects/currency"

module Payment
  module SDK
    module Shared
      module Domain
        module ValueObjects
          # Immutable value object representing a monetary amount in minor units (cents)
          # paired with a {Currency}.
          class Money
            include Comparable

            # @return [Integer] amount in minor currency units (e.g. cents)
            attr_reader :amount
            # @return [Currency] associated ISO 4217 currency value object
            attr_reader :currency

            # @param amount [Integer] integer amount in smallest currency unit
            # @param currency [String, Symbol, Currency] currency code or {Currency} instance
            # @raise [ArgumentError] when `amount` is not an `Integer` or `currency` is invalid
            def initialize(amount, currency)
              raise ArgumentError, "amount must be an Integer (representing smallest currency unit)" unless amount.is_a?(Integer)

              @amount = amount
              @currency = currency.is_a?(Currency) ? currency : Currency.new(currency)
              freeze
            end

            # Compares two {Money} instances of the same currency.
            #
            # @param other [Object]
            # @return [Integer, nil] `-1`, `0`, `1`, or `nil` if `other` is not a {Money}
            # @raise [ArgumentError] when comparing {Money} instances with different currencies
            def <=>(other)
              return nil unless other.is_a?(Money)
              raise ArgumentError, "Cannot compare Money with different currencies: #{currency} vs #{other.currency}" if currency != other.currency

              amount <=> other.amount
            end

            # Adds two {Money} instances of the same currency.
            #
            # @param other [Money]
            # @return [Money]
            # @raise [ArgumentError] when currencies do not match
            def +(other)
              ensure_same_currency!(other)
              Money.new(amount + other.amount, currency)
            end

            # Subtracts another {Money} instance of the same currency.
            #
            # @param other [Money]
            # @return [Money]
            # @raise [ArgumentError] when currencies do not match
            def -(other)
              ensure_same_currency!(other)
              Money.new(amount - other.amount, currency)
            end

            # Value equality comparison.
            #
            # @param other [Object]
            # @return [Boolean]
            def ==(other)
              other.is_a?(Money) && other.amount == amount && other.currency == currency
            end
            alias_method :eql?, :==

            # @return [Integer] hash code based on {#amount} and {#currency}
            def hash
              [amount, currency].hash
            end

            # @return [String] formatted string `"<amount> <currency>"`
            def to_s
              "#{amount} #{currency}"
            end

            private

            def ensure_same_currency!(other)
              raise ArgumentError, "currency mismatch: #{currency} != #{other.currency}" if currency != other.currency
            end
          end
        end
      end
    end
  end
end
