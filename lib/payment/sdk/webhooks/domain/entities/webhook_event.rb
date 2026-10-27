# frozen_string_literal: true

module Payment
  module SDK
    module Webhooks
      module Domain
        module Entities
          WebhookEvent = Data.define(
            :delivery_id,
            :event_id,
            :event_type,
            :created_at,
            :data,
            :raw_payload
          ) do
            def payment_intent_id
              return nil unless data.is_a?(Hash)

              object_id = data.dig(:object, :id) || data.dig("object", "id")
              return object_id if object_id && object_id.to_s.start_with?("pi_")

              data[:payment_intent_id] || data["payment_intent_id"]
            end

            def charge_id
              return nil unless data.is_a?(Hash)

              object_id = data.dig(:object, :id) || data.dig("object", "id")
              return object_id if object_id && object_id.to_s.start_with?("ch_")

              data[:charge_id] || data["charge_id"]
            end

            def refund_id
              return nil unless data.is_a?(Hash)

              object_id = data.dig(:object, :id) || data.dig("object", "id")
              return object_id if object_id && object_id.to_s.start_with?("re_")

              data[:refund_id] || data["refund_id"]
            end
          end
        end
      end
    end
  end
end
