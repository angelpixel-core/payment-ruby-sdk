# frozen_string_literal: true

require "payment/sdk/domain/reconciliation/ports/snapshot/store"
require "thread"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        module Persistence
          module Snapshot
            module Store
              class InMemory
                include Domain::Reconciliation::Ports::Snapshot::Store

                def initialize
                  @store = {}
                  @mutex = Mutex.new
                end

                def save(snapshot)
                  @mutex.synchronize do
                    id = snapshot_id(snapshot)
                    @store[id] = snapshot.dup
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
