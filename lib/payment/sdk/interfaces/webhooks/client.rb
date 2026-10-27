# frozen_string_literal: true

require "json"
require "payment/sdk/application/webhooks/use_cases/process"
require "payment/sdk/infrastructure/adapters/crypto/signature/verifier/hmac_sha256"
require "payment/sdk/infrastructure/adapters/persistence/inbox/store/in_memory"
require "payment/sdk/infrastructure/adapters/webhooks/event_parser"

module Payment
  module SDK
    module Interfaces
      module Webhooks
        class Client
          attr_reader :secret, :default_inbox_store, :verifier

          def initialize(secret:, inbox_store: nil, verifier: nil)
            @secret = secret
            @default_inbox_store = inbox_store || Infrastructure::Adapters::Persistence::Inbox::Store::InMemory.new
            @verifier = verifier || Infrastructure::Adapters::Crypto::Signature::Verifier::HmacSha256.new
          end

          def process(payload:, signature_header:, projection:, inbox_store: nil)
            store = inbox_store || @default_inbox_store
            use_case = Application::Webhooks::UseCases::Process.new(
              inbox_store: store,
              projection: projection,
              verifier: @verifier
            )
            use_case.call(
              delivery_id: extract_delivery_id(payload),
              raw_payload: payload.is_a?(String) ? payload : JSON.generate(payload),
              signature_header: signature_header,
              secret: @secret
            )
          end

          def parse_event(payload)
            Infrastructure::Adapters::Webhooks::EventParser.parse(payload)
          end

          private

          def extract_delivery_id(payload)
            parsed = payload.is_a?(String) ? JSON.parse(payload, symbolize_names: true) : payload.transform_keys(&:to_sym)
            parsed[:delivery_id]
          end
        end
      end
    end
  end
end
