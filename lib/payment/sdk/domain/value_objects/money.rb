# frozen_string_literal: true

require_relative "currency"

module Payment
  module SDK
    module Domain
      module ValueObjects
        class Money
          include Comparable

          attr_reader :amount, :currency

          def initialize(amount, currency)
            raise ArgumentError, "Amount must be an integer" unless amount.is_a?(Integer)
            
            @amount = amount
            @currency = currency.is_a?(Currency) ? currency : Currency.new(currency)
            freeze
          end

          def +(other)
            check_currency_match!(other)
            Money.new(amount + other.amount, currency)
          end

          def -(other)
            check_currency_match!(other)
            Money.new(amount - other.amount, currency)
          end

          def <=>(other)
            return nil unless other.is_a?(Money)
            return nil unless currency == other.currency
            amount <=> other.amount
          end

          def ==(other)
            return false unless other.is_a?(Money)
            amount == other.amount && currency == other.currency
          end
          alias eql? ==

          def hash
            [amount, currency].hash
          end

          private

          def check_currency_match!(other)
            raise ArgumentError, "Cannot operate on different currencies" unless currency == other.currency
          end
        end
      end
    end
  end
end
