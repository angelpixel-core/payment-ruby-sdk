# frozen_string_literal: true

require "securerandom"

module Payment
  module SDK
    module Shared
      module Domain
        module ValueObjects
          # Immutable value object representing a request idempotency key.
          class IdempotencyKey
            # @return [String] normalized non-empty idempotency key string
            attr_reader :value

            # @param value [String, nil] explicit key string, or `nil` to generate a random UUID
            # @raise [ArgumentError] when the stripped value is empty
            def initialize(value = nil)
              value = value ? value.to_s.strip : SecureRandom.uuid

              raise ArgumentError, "idempotency_key cannot be empty" if value.empty?

              @value = value
              freeze
            end

            # Value equality comparison.
            #
            # @param other [Object]
            # @return [Boolean]
            def ==(other)
              other.is_a?(IdempotencyKey) && other.value == value
            end
            alias_method :eql?, :==

            # @return [Integer] hash code based on {#value}
            def hash
              value.hash
            end

            # @return [String] idempotency key string
            def to_s
              value
            end
          end
        end
      end
    end
  end
end
