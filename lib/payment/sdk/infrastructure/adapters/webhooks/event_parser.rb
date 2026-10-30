# frozen_string_literal: true

require "json"
require "time"
require "payment/sdk/webhooks/domain/entities/webhook_event"
require "payment/sdk/errors"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        # Webhook parsing adapters.
        module Webhooks
          # Parses raw JSON strings or hashes into {Payment::SDK::Webhooks::Domain::Entities::WebhookEvent} instances.
          class EventParser
            # Parses and validates a webhook payload.
            #
            # @param payload [String, Hash] raw JSON string or hash payload
            # @return [Payment::SDK::Webhooks::Domain::Entities::WebhookEvent]
            # @raise [Payment::SDK::InvalidRequestError] when `delivery_id`, `event_id`, or `event_type` is missing, or JSON is malformed
            def self.parse(payload)
              parsed = payload.is_a?(String) ? JSON.parse(payload, symbolize_names: true) : payload.transform_keys(&:to_sym)

              delivery_id = parsed[:delivery_id]
              event_id = parsed[:event_id] || parsed[:id]
              event_type = parsed[:event_type] || parsed[:type]

              if delivery_id.nil? || delivery_id.to_s.empty?
                raise Payment::SDK::InvalidRequestError.new("Missing delivery_id in webhook payload")
              end

              if event_id.nil? || event_id.to_s.empty?
                raise Payment::SDK::InvalidRequestError.new("Missing event_id in webhook payload")
              end

              if event_type.nil? || event_type.to_s.empty?
                raise Payment::SDK::InvalidRequestError.new("Missing event_type in webhook payload")
              end

              Payment::SDK::Webhooks::Domain::Entities::WebhookEvent.new(
                delivery_id: delivery_id,
                event_id: event_id,
                event_type: event_type,
                data: parsed[:data],
                created_at: parsed[:created_at] || Time.now.utc.iso8601,
                raw_payload: payload.is_a?(String) ? payload : JSON.generate(payload)
              )
            rescue JSON::ParserError => e
              raise Payment::SDK::InvalidRequestError.new("Invalid JSON payload: #{e.message}")
            end
          end
        end
      end
    end
  end
end
