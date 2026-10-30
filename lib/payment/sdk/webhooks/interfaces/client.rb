# frozen_string_literal: true

require "payment/sdk/webhooks/application/use_cases/process"
require "payment/sdk/infrastructure/adapters/crypto/signature/verifier/hmac_sha256"
require "payment/sdk/infrastructure/adapters/persistence/inbox/store/in_memory"
require "payment/sdk/infrastructure/adapters/webhooks/event_parser"
require "json"

module Payment
  module SDK
    module Webhooks
      # Driving interface layer of the webhooks bounded context.
      module Interfaces
        # Entry point of the webhooks bounded context (inbox-first processing).
        class Client
          # @return [String, nil] webhook signing secret
          attr_reader :secret
          # @return [Domain::Ports::Inbox::Store] default inbox store implementation
          attr_reader :inbox_store
          # @return [Domain::Ports::Signature::Verifier] signature verifier implementation
          attr_reader :verifier

          # @param secret [String, nil] webhook signing secret
          # @param inbox_store [Domain::Ports::Inbox::Store, nil] inbox store port implementation (in-memory by default)
          # @param verifier [Domain::Ports::Signature::Verifier, nil] signature verifier port implementation (HMAC-SHA256 by default)
          def initialize(secret:, inbox_store: nil, verifier: nil)
            @secret = secret
            @inbox_store = inbox_store || default_inbox_store
            @verifier = verifier || default_verifier
          end

          # Verifies the signature, deduplicates through the inbox, and applies the projection.
          #
          # @param payload [String, Hash] raw JSON body or parsed hash payload
          # @param signature_header [String] value of the signature header
          # @param projection [#apply!] projection object responding to `#apply!(inbox_entry:)`
          # @param delivery_id [String, nil] extracted from the payload when omitted
          # @param inbox_store [Domain::Ports::Inbox::Store, nil] overrides the client's inbox store
          # @return [Hash] processing result (`{ status: :processed | :duplicate, entry: Hash }`)
          # @raise [Payment::SDK::SignatureVerificationError] when the signature is invalid
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

          # Parses a raw webhook payload into a {Domain::Entities::WebhookEvent}.
          #
          # @param payload [String, Hash] raw body or parsed payload
          # @return [Domain::Entities::WebhookEvent]
          # @raise [Payment::SDK::InvalidRequestError] when required fields are missing or JSON is invalid
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
