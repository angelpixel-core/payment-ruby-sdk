# frozen_string_literal: true

require "payment/sdk/infrastructure/adapters/persistence/snapshot/store/in_memory"

module Payment
  module SDK
    module Infrastructure
      module Persistence
        InMemorySnapshotStore = Payment::SDK::Infrastructure::Adapters::Persistence::Snapshot::Store::InMemory
      end
    end
  end
end
