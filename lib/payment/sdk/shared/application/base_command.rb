# frozen_string_literal: true

require "payment/sdk/shared/domain/value_objects/idempotency_key"

module Payment
  module SDK
    module Shared
      module Application
        class BaseCommand
          attr_reader :http_client

          def initialize(http_client)
            @http_client = http_client
          end

          def call(**options)
            raise NotImplementedError, "#{self.class} must implement #call"
          end

          protected

          def normalize_idempotency_key(key)
            if key.is_a?(Domain::ValueObjects::IdempotencyKey)
              key
            elsif key.nil? || key.to_s.strip.empty?
              raise ArgumentError, "idempotency_key is required for state-mutating commands"
            else
              Domain::ValueObjects::IdempotencyKey.new(key)
            end
          end
        end
      end
    end
  end
end
