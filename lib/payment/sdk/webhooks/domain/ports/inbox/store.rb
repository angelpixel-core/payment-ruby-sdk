# frozen_string_literal: true

module Payment
  module SDK
    module Webhooks
      module Domain
        # Secondary ports of the webhooks bounded context.
        module Ports
          # Transactional inbox port namespace.
          module Inbox
            # Secondary port defining the persistence contract for idempotent webhook processing.
            module Store
              # Persists a newly received webhook delivery entry.
              #
              # @param entry [Hash] inbox entry containing `:delivery_id`, `:payload`, `:status`, `:created_at`
              # @return [Hash] persisted entry
              # @raise [NotImplementedError] when not implemented by an adapter
              def save(entry)
                raise NotImplementedError, "#{self.class} must implement #save"
              end

              # Looks up an existing inbox entry by its delivery identifier.
              #
              # @param delivery_id [String] unique delivery identifier
              # @return [Hash, nil] matching inbox entry or `nil`
              # @raise [NotImplementedError] when not implemented by an adapter
              def find_by_delivery_id(delivery_id)
                raise NotImplementedError, "#{self.class} must implement #find_by_delivery_id"
              end

              # Updates the lifecycle status (and optional failure reason) of an inbox entry.
              #
              # @param delivery_id [String] unique delivery identifier
              # @param status [Symbol] new status (`:validated`, `:processed`, `:rejected_signature`, `:failed`)
              # @param failure_reason [String, nil] optional error message when failed or rejected
              # @return [Hash, nil] updated entry
              # @raise [NotImplementedError] when not implemented by an adapter
              def update_status(delivery_id:, status:, failure_reason: nil)
                raise NotImplementedError, "#{self.class} must implement #update_status"
              end
            end
          end
        end
      end
    end
  end
end
