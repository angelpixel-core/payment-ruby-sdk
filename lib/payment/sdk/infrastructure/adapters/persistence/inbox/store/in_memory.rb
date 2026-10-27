# frozen_string_literal: true

require "payment/sdk/domain/webhooks/ports/inbox/store"
require "thread"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        module Persistence
          module Inbox
            module Store
              class InMemory
                include Payment::SDK::Domain::Webhooks::Ports::Inbox::Store

                def initialize
                  @store = {}
                  @mutex = Mutex.new
                end

                def find_by_delivery_id(delivery_id)
                  @mutex.synchronize do
                    entry = @store[delivery_id]
                    entry ? entry.dup : nil
                  end
                end

                def persist(entry)
                  @mutex.synchronize do
                    if @store.key?(entry[:delivery_id])
                      raise ArgumentError, "Duplicate delivery_id: #{entry[:delivery_id]}"
                    end

                    @store[entry[:delivery_id]] = entry.dup
                    entry.dup
                  end
                end

                def update(delivery_id, attributes)
                  @mutex.synchronize do
                    entry = @store[delivery_id]
                    return nil unless entry

                    entry.merge!(attributes)
                    entry.dup
                  end
                end

                def clear!
                  @mutex.synchronize { @store.clear }
                end
              end
            end
          end
        end
      end
    end
  end
end
