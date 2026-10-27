# frozen_string_literal: true

require "payment/sdk/infrastructure/adapters/persistence/inbox/store/in_memory"

module Payment
  module SDK
    module Infrastructure
      module Persistence
        InMemoryInboxStore = Payment::SDK::Infrastructure::Adapters::Persistence::Inbox::Store::InMemory
      end
    end
  end
end
