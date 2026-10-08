# frozen_string_literal: true

module Payment
  module SDK
    module Application
      module UseCases
        class ProcessWebhook
          def initialize(inbox_store:, projection:, verifier:)
            @inbox_store = inbox_store
            @projection = projection
            @verifier = verifier
          end

          def call(delivery_id:, raw_payload:, signature_header:, secret:)
            existing_entry = @inbox_store.find_by_delivery_id(delivery_id)

            if existing_entry
              if existing_entry[:raw_payload] == raw_payload
                return { status: :duplicate, entry: existing_entry }
              else
                raise ArgumentError, "delivery_id payload conflict"
              end
            end

            entry = {
              delivery_id: delivery_id,
              raw_payload: raw_payload,
              status: :received,
              created_at: Time.now.utc
            }
            
            @inbox_store.persist(entry)

            begin
              @verifier.verify(payload: raw_payload, signature: signature_header, secret: secret)
            rescue StandardError => e
              # Catch SignatureVerificationError or similar
              @inbox_store.update(delivery_id, status: :rejected_signature, failure_reason: e.message)
              raise e
            end

            @inbox_store.update(delivery_id, status: :validated)

            begin
              current_entry = @inbox_store.find_by_delivery_id(delivery_id)
              @projection.apply!(inbox_entry: current_entry)
              
              @inbox_store.update(delivery_id, status: :processed)
              { status: :processed, entry: @inbox_store.find_by_delivery_id(delivery_id) }
            rescue StandardError => e
              @inbox_store.update(delivery_id, status: :failed, failure_reason: e.message)
              raise e
            end
          end
        end
      end
    end
  end
end
