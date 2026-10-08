# frozen_string_literal: true

require "payment/sdk/domain/value_objects/idempotency_key"

module Payment
  module SDK
    module Application
      module Commands
        class BaseCommand
          attr_reader :http_client

          def initialize(http_client)
            @http_client = http_client
          end

          protected

          def require_idempotency_key!(key)
            if key.nil? || key.to_s.strip.empty?
              raise ArgumentError, "Idempotency-Key is required for all mutation commands"
            end
            Payment::SDK::Domain::ValueObjects::IdempotencyKey.new(key).value
          end

          def default_headers(idempotency_key)
            {
              "Idempotency-Key" => require_idempotency_key!(idempotency_key)
            }
          end
        end
      end
    end
  end
end
