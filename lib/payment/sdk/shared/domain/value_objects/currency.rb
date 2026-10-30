# frozen_string_literal: true

module Payment
  module SDK
    module Shared
      module Domain
        # Immutable value objects shared across bounded contexts.
        module ValueObjects
          # Immutable value object representing a 3-letter ISO 4217 currency code.
          class Currency
            # @return [String] normalized lowercase 3-letter ISO currency code
            attr_reader :code

            # @param code [String, Symbol] 3-letter ISO 4217 currency code (e.g. `"usd"`, `"EUR"`)
            # @raise [ArgumentError] when `code` is nil, blank, or not 3 ASCII letters
            def initialize(code)
              raise ArgumentError, "currency cannot be nil or empty" if code.nil? || code.to_s.strip.empty?

              normalized = code.to_s.strip.downcase
              raise ArgumentError, "currency must be a valid 3-letter ISO code" unless normalized.match?(/\A[a-z]{3}\z/)

              @code = normalized
              freeze
            end

            # Value equality comparison.
            #
            # @param other [Object]
            # @return [Boolean]
            def ==(other)
              other.is_a?(Currency) && other.code == code
            end
            alias_method :eql?, :==

            # @return [Integer] hash code based on {#code}
            def hash
              code.hash
            end

            # @return [String] lowercase currency code
            def to_s
              code
            end
          end
        end
      end
    end
  end
end
