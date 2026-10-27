# frozen_string_literal: true

require "payment/sdk/webhooks/application/use_cases/process"
require "payment/sdk/infrastructure/adapters/crypto/signature/verifier/hmac_sha256"
require "payment/sdk/infrastructure/adapters/persistence/inbox/store/in_memory"
require "payment/sdk/infrastructure/adapters/webhooks/event_parser"
require "json"

module Payment
  module SDK
    module Webhooks
      module Interfaces
        class Client
          attr_reader :secret, :inbox_store, :verifier

          def initialize(secret:, inbox_store: nil, verifier: nil)
            @secret = secret
            @inbox_store = inbox_store || default_inbox_store
            @verifier = verifier || default_verifier
          end

          def process(payload:, signature_header:, projection:, delivery_id: nil, inbox_store: nil)
            store = inbox_store || @inbox_store
            actual_delivery_id = delivery_id || extract_delivery_id(payload)

            use_case = Application::UseCases::Process.new(
              inbox_store: store,
              projection: projection,
              verifier: @verifier
            )

            raw_payload = payload.is_a?(String) ? payload : JSON.generate(payload)

            use_case.call(
              delivery_id: actual_delivery_id,
              raw_payload: raw_payload,
              signature_header: signature_header,
              secret: @secret
            )
          end

          def parse_event(payload)
            Infrastructure::Adapters::Webhooks::EventParser.parse(payload)
          end

          private

          def default_inbox_store
            @default_inbox_store ||= Infrastructure::Adapters::Persistence::Inbox::Store::InMemory.new
          end

          def default_verifier
            @default_verifier ||= Infrastructure::Adapters::Crypto::Signature::Verifier::HmacSha256.new
          end

          def extract_delivery_id(payload)
            parsed = payload.is_a?(String) ? JSON.parse(payload, symbolize_names: true) : payload.transform_keys(&:to_sym)
            parsed[:delivery_id] || parsed[:id]
          end
        end
      end
    end
  end
end
