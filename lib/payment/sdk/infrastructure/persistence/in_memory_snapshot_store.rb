# frozen_string_literal: true

require "payment/sdk/domain/ports/snapshot_store_port"
require "thread"

module Payment
  module SDK
    module Infrastructure
      module Persistence
        class InMemorySnapshotStore
          include Payment::SDK::Domain::Ports::SnapshotStorePort

          def initialize
            @store = {}
            @mutex = Mutex.new
          end

          def save(snapshot)
            @mutex.synchronize do
              @store[snapshot[:id]] = snapshot.dup
              snapshot.dup
            end
          end

          def find(id)
            @mutex.synchronize do
              entry = @store[id]
              entry ? entry.dup : nil
            end
          end

          def all
            @mutex.synchronize do
              @store.values.map(&:dup)
            end
          end
        end
      end
    end
  end
end
