# frozen_string_literal: true

require "payment/sdk/shared/domain/value_objects/currency"

module Payment
  module SDK
    module Shared
      module Domain
        module ValueObjects
          class Money
            include Comparable

            attr_reader :amount, :currency

            def initialize(amount, currency)
              raise ArgumentError, "amount must be an Integer (representing smallest currency unit)" unless amount.is_a?(Integer)

              @amount = amount
              @currency = currency.is_a?(Currency) ? currency : Currency.new(currency)
              freeze
            end

            def <=>(other)
              return nil unless other.is_a?(Money)
              raise ArgumentError, "Cannot compare Money with different currencies: #{currency} vs #{other.currency}" if currency != other.currency

              amount <=> other.amount
            end

            def +(other)
              ensure_same_currency!(other)
              Money.new(amount + other.amount, currency)
            end

            def -(other)
              ensure_same_currency!(other)
              Money.new(amount - other.amount, currency)
            end

            def ==(other)
              other.is_a?(Money) && other.amount == amount && other.currency == currency
            end
            alias_method :eql?, :==

            def hash
              [amount, currency].hash
            end

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
