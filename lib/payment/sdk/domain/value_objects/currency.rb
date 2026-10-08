# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module ValueObjects
        class Currency
          attr_reader :code

          def initialize(code)
            raise ArgumentError, "Currency code cannot be nil or empty" if code.nil? || code.to_s.strip.empty?
            
            normalized_code = code.to_s.strip.downcase
            raise ArgumentError, "Invalid currency code format" unless normalized_code.match?(/\A[a-z]{3}\z/)

            @code = normalized_code
            freeze
          end

          def ==(other)
            return false unless other.is_a?(Currency)
            code == other.code
          end
          alias eql? ==

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
