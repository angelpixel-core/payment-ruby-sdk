# frozen_string_literal: true

module Payment
  module SDK
    module Shared
      module Domain
        module ValueObjects
          class Currency
            attr_reader :code

            def initialize(code)
              raise ArgumentError, "currency cannot be nil or empty" if code.nil? || code.to_s.strip.empty?

              normalized = code.to_s.strip.downcase
              raise ArgumentError, "currency must be a valid 3-letter ISO code" unless normalized.match?(/\A[a-z]{3}\z/)

              @code = normalized
              freeze
            end

            def ==(other)
              other.is_a?(Currency) && other.code == code
            end
            alias_method :eql?, :==

            def hash
              code.hash
            end

            def to_s
              code
            end
          end
        end
      end
    end
  end
end
