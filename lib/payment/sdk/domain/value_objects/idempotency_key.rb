# frozen_string_literal: true

require "securerandom"

module Payment
  module SDK
    module Domain
      module ValueObjects
        class IdempotencyKey
          attr_reader :value

          def initialize(value = nil)
            @value = value ? validate_and_format(value) : SecureRandom.uuid
            freeze
          end

          def ==(other)
            return false unless other.is_a?(IdempotencyKey)
            value == other.value
          end
          alias eql? ==

          def hash
            value.hash
          end

          def to_s
            value
          end

          private

          def validate_and_format(val)
            normalized = val.to_s.strip
            raise ArgumentError, "Idempotency key cannot be empty" if normalized.empty?
            normalized
          end
        end
      end
    end
  end
end
