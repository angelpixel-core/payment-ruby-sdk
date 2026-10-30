# frozen_string_literal: true

require "payment/sdk/reconciliation/domain/ports/snapshot/store"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        module Persistence
          # Reconciliation snapshot persistence adapters.
          module Snapshot
            # Snapshot store adapter implementations.
            module Store
              # Thread-safe in-memory implementation of {Payment::SDK::Reconciliation::Domain::Ports::Snapshot::Store}.
              class InMemory
                include Reconciliation::Domain::Ports::Snapshot::Store

                # Initializes an empty mutex-synchronized in-memory snapshot store.
                def initialize
                  @store = {}
                  @mutex = Mutex.new
                end

                # Saves a snapshot entry keyed by its identifier.
                #
                # @param snapshot [Hash, #id] snapshot entry to persist
                # @return [Hash, Object] shallow copy of the saved snapshot
                def save(snapshot)
                  @mutex.synchronize do
                    id = snapshot_id(snapshot)
                    @store[id] = snapshot.dup
                    snapshot.dup
                  end
                end

                # Finds a stored snapshot by its identifier.
                #
                # @param id [String] snapshot identifier
                # @return [Hash, nil] shallow copy of the snapshot or `nil`
                def find(id)
                  @mutex.synchronize do
                    @store[id]&.dup
                  end
                end

                # Returns shallow copies of all stored snapshots.
                #
                # @return [Array<Hash>]
                def all
                  @mutex.synchronize do
                    @store.values.map(&:dup)
                  end
                end

                # Clears all stored snapshots.
                #
                # @return [Hash]
                def clear!
                  @mutex.synchronize { @store.clear }
                end

                private

                def snapshot_id(snapshot)
                  if snapshot.respond_to?(:id)
                    snapshot.id
                  elsif snapshot.respond_to?(:[])
                    snapshot[:id]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
