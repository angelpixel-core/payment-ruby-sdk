# frozen_string_literal: true

require "payment/sdk/shared/domain/concerns/payload_extractable"

module Payment
  module SDK
    module Webhooks
      module Domain
        module Entities
          class WebhookEvent < Data.define(
            :delivery_id,
            :event_id,
            :event_type,
            :created_at,
            :data,
            :raw_payload
          )
            include Shared::Domain::Concerns::PayloadExtractable

            def payment_intent_id
              extract_prefixed_id("pi_", :payment_intent_id)
            end

            def charge_id
              extract_prefixed_id("ch_", :charge_id)
            end

            def refund_id
              extract_prefixed_id("re_", :refund_id)
            end
          end
        end
      end
    end
  end
end
