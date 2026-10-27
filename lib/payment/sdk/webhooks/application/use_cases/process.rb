# frozen_string_literal: true

require "payment/sdk/errors"

module Payment
  module SDK
    module Webhooks
      module Application
        module UseCases
          class Process
            def initialize(inbox_store:, projection:, verifier:)
              @inbox_store = inbox_store
              @projection = projection
              @verifier = verifier
            end

            def call(delivery_id:, raw_payload:, signature_header:, secret:, timestamp_tolerance: 300)
              existing_entry = @inbox_store.find_by_delivery_id(delivery_id)

              if existing_entry
                if existing_entry[:payload] == raw_payload
                  return { status: :duplicate, entry: existing_entry }
                else
                  raise ArgumentError, "delivery_id payload conflict: #{delivery_id} already exists with different payload"
                end
              end

              entry = {
                delivery_id: delivery_id,
                payload: raw_payload,
                status: :received,
                created_at: Time.now.utc
              }
              @inbox_store.save(entry)

              begin
                @verifier.verify(
                  payload: raw_payload,
                  signature: signature_header,
                  secret: secret,
                  timestamp_tolerance: timestamp_tolerance
                )
                @inbox_store.update_status(delivery_id: delivery_id, status: :validated)
              rescue SignatureVerificationError => e
                @inbox_store.update_status(delivery_id: delivery_id, status: :rejected_signature, failure_reason: e.message)
                raise e
              end

              begin
                current_entry = @inbox_store.find_by_delivery_id(delivery_id)
                projection_entry = {
                  delivery_id: current_entry[:delivery_id],
                  raw_payload: current_entry[:payload],
                  status: current_entry[:status]
                }
                @projection.apply!(inbox_entry: projection_entry)
                @inbox_store.update_status(delivery_id: delivery_id, status: :processed)
              rescue StandardError => e
                @inbox_store.update_status(delivery_id: delivery_id, status: :failed, failure_reason: e.message)
                raise e
              end

              { status: :processed, entry: @inbox_store.find_by_delivery_id(delivery_id) }
            end
          end
        end
      end
    end
  end
end
