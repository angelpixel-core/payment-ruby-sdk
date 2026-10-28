# frozen_string_literal: true

module Payment
  module SDK
    module Reconciliation
      module Domain
        module Ports
          # Reconciliation snapshot persistence port namespace.
          module Snapshot
            # Secondary port defining the persistence contract for reconciliation snapshots.
            module Store
              # Saves a reconciliation snapshot entry.
              #
              # @param snapshot [Hash] reconciliation snapshot entry
              # @return [Hash] saved snapshot entry
              # @raise [NotImplementedError] when not implemented by an adapter
              def save(snapshot)
                raise NotImplementedError, "#{self.class} must implement #save"
              end

              # Finds a reconciliation snapshot entry by its identifier.
              #
              # @param id [String] snapshot identifier (`"<run_id>:<payment_intent_id>"`)
              # @return [Hash, nil] matching snapshot entry or `nil`
              # @raise [NotImplementedError] when not implemented by an adapter
              def find(id)
                raise NotImplementedError, "#{self.class} must implement #find"
              end

              # Returns all stored reconciliation snapshot entries.
              #
              # @return [Array<Hash>]
              # @raise [NotImplementedError] when not implemented by an adapter
              def all
                raise NotImplementedError, "#{self.class} must implement #all"
              end
            end
          end
        end
      end
    end
  end
end
