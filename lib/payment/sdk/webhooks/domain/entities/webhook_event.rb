# frozen_string_literal: true

require "payment/sdk/shared/domain/concerns/payload_extractable"

module Payment
  module SDK
    # Webhooks bounded context (signature verification, transactional inbox, and event parsing).
    module Webhooks
      # Domain layer of the webhooks bounded context.
      module Domain
        # Domain entities of the webhooks bounded context.
        module Entities
          WebhookEventData = Data.define(
            :delivery_id,
            :event_id,
            :event_type,
            :created_at,
            :data,
            :raw_payload
          )
          private_constant :WebhookEventData

          # Immutable value-based entity representing a verified or parsed webhook event.
          #
          # Inherits from a `Data.define` structure and includes
          # {Payment::SDK::Shared::Domain::Concerns::PayloadExtractable} for extracting
          # prefixed entity identifiers from {#data}.
          #
          # @!attribute [r] delivery_id
          #   @return [String] unique webhook delivery identifier
          # @!attribute [r] event_id
          #   @return [String] unique event identifier
          # @!attribute [r] event_type
          #   @return [String] event type name (e.g. `"payment_intent.succeeded"`)
          # @!attribute [r] created_at
          #   @return [String, nil] ISO 8601 event creation timestamp
          # @!attribute [r] data
          #   @return [Hash, nil] structured event data payload
          # @!attribute [r] raw_payload
          #   @return [String] raw JSON string of the webhook body
          class WebhookEvent < WebhookEventData
            include Shared::Domain::Concerns::PayloadExtractable

            # Extracts the `pi_...` payment intent identifier from {#data}, if present.
            #
            # @return [String, nil]
            def payment_intent_id
              extract_prefixed_id("pi_", :payment_intent_id)
            end

            # Extracts the `ch_...` charge identifier from {#data}, if present.
            #
            # @return [String, nil]
            def charge_id
              extract_prefixed_id("ch_", :charge_id)
            end

            # Extracts the `re_...` refund identifier from {#data}, if present.
            #
            # @return [String, nil]
            def refund_id
              extract_prefixed_id("re_", :refund_id)
            end
          end
        end
      end
    end
  end
end
