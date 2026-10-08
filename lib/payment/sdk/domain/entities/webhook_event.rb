# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Entities
        class WebhookEvent
          attr_reader :delivery_id, :event_id, :event_type, :data, :created_at

          def initialize(delivery_id:, event_id:, event_type:, data:, created_at:)
            @delivery_id = delivery_id.to_s
            @event_id = event_id.to_s
            @event_type = event_type.to_s
            @data = data
            @created_at = created_at
            freeze
          end

          def payment_intent_id
            dig_data("payment_intent_id") || dig_data("object", "id") if event_type.start_with?("payment_intent.")
          end

          def charge_id
            dig_data("charge_id") || dig_data("object", "id") if event_type.start_with?("charge.")
          end

          private

          def dig_data(*keys)
            return nil unless data.is_a?(Hash)
            data.dig(*keys) || data.dig(*keys.map(&:to_sym))
          end
        end
      end
    end
  end
end
