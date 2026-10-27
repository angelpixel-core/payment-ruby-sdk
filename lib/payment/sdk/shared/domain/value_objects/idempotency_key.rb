# frozen_string_literal: true

require "securerandom"

module Payment
  module SDK
    module Shared
      module Domain
        module ValueObjects
          class IdempotencyKey
            attr_reader :value

            def initialize(value = nil)
              value = value ? value.to_s.strip : SecureRandom.uuid

              raise ArgumentError, "idempotency_key cannot be empty" if value.empty?

              @value = value
              freeze
            end

            def ==(other)
              other.is_a?(IdempotencyKey) && other.value == value
            end
            alias_method :eql?, :==

            def hash
              value.hash
            end

            def to_s
              value
            end
          end
        end
      end
    end
  end
end
