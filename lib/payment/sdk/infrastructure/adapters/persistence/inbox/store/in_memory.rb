# frozen_string_literal: true

require "payment/sdk/webhooks/domain/ports/inbox/store"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        # Persistence adapters for webhook inbox and reconciliation snapshots.
        module Persistence
          # Webhook transactional inbox persistence adapters.
          module Inbox
            # Inbox store adapter implementations.
            module Store
              # Thread-safe in-memory implementation of {Payment::SDK::Webhooks::Domain::Ports::Inbox::Store}.
              class InMemory
                include Payment::SDK::Webhooks::Domain::Ports::Inbox::Store

                # @return [Numeric, nil] time-to-live in seconds for stored entries
                attr_reader :ttl_seconds

                # Initializes an empty mutex-synchronized in-memory inbox store with optional TTL.
                #
                # @param ttl_seconds [Numeric, nil] optional expiration in seconds for stored entries
                def initialize(ttl_seconds: nil)
                  @store = {}
                  @created_at_store = {}
                  @ttl_seconds = ttl_seconds
                  @mutex = Mutex.new
                end

                # Finds a stored inbox entry by delivery identifier.
                #
                # @param delivery_id [String] unique delivery identifier
                # @return [Hash, nil] shallow copy of the stored entry or `nil`
                def find_by_delivery_id(delivery_id)
                  @mutex.synchronize do
                    evict_expired!
                    @store[delivery_id]&.dup
                  end
                end

                # Persists a new inbox entry, raising if the `delivery_id` already exists.
                #
                # @param entry [Hash] inbox entry with `:delivery_id`
                # @return [Hash] shallow copy of the stored entry
                # @raise [ArgumentError] when `entry[:delivery_id]` is already present
                def save(entry)
                  @mutex.synchronize do
                    evict_expired!

                    if @store.key?(entry[:delivery_id])
                      raise ArgumentError, "Duplicate delivery_id: #{entry[:delivery_id]}"
                    end

                    @store[entry[:delivery_id]] = entry.dup
                    @created_at_store[entry[:delivery_id]] = monotonic_now
                    entry.dup
                  end
                end

                # Merges attributes into an existing inbox entry.
                #
                # @param delivery_id [String] unique delivery identifier
                # @param attributes [Hash] attributes to merge
                # @return [Hash, nil] updated entry copy or `nil` if not found
                def update(delivery_id, attributes)
                  @mutex.synchronize do
                    evict_expired!

                    entry = @store[delivery_id]
                    return nil unless entry

                    entry.merge!(attributes)
                    entry.dup
                  end
                end

                # Updates the status and optional failure reason of an existing inbox entry.
                #
                # @param delivery_id [String] unique delivery identifier
                # @param status [Symbol] new lifecycle status
                # @param failure_reason [String, nil] optional failure reason
                # @return [Hash, nil] updated entry copy or `nil` if not found
                def update_status(delivery_id:, status:, failure_reason: nil)
                  attrs = {status: status}
                  attrs[:failure_reason] = failure_reason if failure_reason
                  update(delivery_id, attrs)
                end

                # Removes all entries from the store.
                #
                # @return [void]
                def clear!
                  @mutex.synchronize do
                    @store.clear
                    @created_at_store.clear
                  end
                end

                private

                def evict_expired!
                  return unless @ttl_seconds

                  now = monotonic_now
                  @created_at_store.delete_if do |delivery_id, timestamp|
                    if (now - timestamp) >= @ttl_seconds
                      @store.delete(delivery_id)
                      true
                    else
                      false
                    end
                  end
                end

                def monotonic_now
                  Process.clock_gettime(Process::CLOCK_MONOTONIC)
                end
              end
            end
          end
        end
      end
    end
  end
end
