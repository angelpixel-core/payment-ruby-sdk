# frozen_string_literal: true

require "payment/sdk/webhooks/domain/ports/inbox/store"
require "thread"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        module Persistence
          module Inbox
            module Store
              class InMemory
                include Payment::SDK::Webhooks::Domain::Ports::Inbox::Store

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
                alias_method :save, :persist

                def update(delivery_id, attributes)
                  @mutex.synchronize do
                    entry = @store[delivery_id]
                    return nil unless entry

                    entry.merge!(attributes)
                    entry.dup
                  end
                end

                def update_status(delivery_id:, status:, failure_reason: nil)
                  attrs = { status: status }
                  attrs[:failure_reason] = failure_reason if failure_reason
                  update(delivery_id, attrs)
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
