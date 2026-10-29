# frozen_string_literal: true

require "json"
require "payment/sdk/webhooks/domain/ports/inbox/store"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        module Persistence
          module Inbox
            module Store
              # Redis-backed transactional inbox adapter implementing
              # {Payment::SDK::Webhooks::Domain::Ports::Inbox::Store}.
              #
              # Interacts with any Redis client via duck-typing (e.g. `redis`, `redis-client`)
              # and supports atomic insertion with a configurable TTL to prevent memory saturation.
              class Redis
                include Payment::SDK::Webhooks::Domain::Ports::Inbox::Store

                # Default Redis key prefix.
                DEFAULT_PREFIX = "payment:webhook:inbox:"
                # Default retention TTL in seconds (7 days).
                DEFAULT_TTL = 7 * 24 * 60 * 60

                # @return [Object] underlying Redis client
                attr_reader :redis
                # @return [String] key prefix for isolation
                attr_reader :prefix
                # @return [Integer, nil] entry retention TTL in seconds
                attr_reader :ttl

                # @param redis [Object] Redis client responding to `#get`, `#set`, `#del`
                # @param prefix [String] key prefix for isolation (defaults to {DEFAULT_PREFIX})
                # @param ttl [Integer, nil] entry retention TTL in seconds (defaults to {DEFAULT_TTL})
                def initialize(redis:, prefix: DEFAULT_PREFIX, ttl: DEFAULT_TTL)
                  @redis = redis
                  @prefix = prefix
                  @ttl = ttl
                end

                # Finds a stored inbox entry by its delivery identifier.
                #
                # @param delivery_id [String] unique delivery identifier
                # @return [Hash, nil] deserialized entry with symbolized keys or `nil`
                def find_by_delivery_id(delivery_id)
                  raw = @redis.get(key_for(delivery_id))
                  return nil if raw.nil? || raw.to_s.empty?

                  deserialize(raw)
                end

                # Atomically persists a new inbox entry using `SET NX`.
                #
                # @param entry [Hash] inbox entry containing `:delivery_id`
                # @return [Hash] copy of the stored entry
                # @raise [ArgumentError] when `delivery_id` is missing or duplicate
                def save(entry)
                  delivery_id = extract_delivery_id(entry)
                  key = key_for(delivery_id)
                  json = JSON.generate(entry)

                  persisted = if @ttl
                    @redis.set(key, json, nx: true, ex: @ttl)
                  else
                    @redis.set(key, json, nx: true)
                  end

                  unless persisted
                    raise ArgumentError, "Duplicate delivery_id: #{delivery_id}"
                  end

                  deserialize(json)
                end

                # Merges attributes into an existing inbox entry.
                #
                # @param delivery_id [String] unique delivery identifier
                # @param attributes [Hash] attributes to merge
                # @return [Hash, nil] updated entry copy or `nil` if not found
                def update(delivery_id, attributes)
                  key = key_for(delivery_id)
                  raw = @redis.get(key)
                  return nil if raw.nil? || raw.to_s.empty?

                  entry = deserialize(raw)
                  attributes.each do |k, v|
                    entry[k.to_sym] = v
                  end
                  json = JSON.generate(entry)

                  if @ttl
                    @redis.set(key, json, ex: @ttl)
                  else
                    @redis.set(key, json)
                  end

                  deserialize(json)
                end

                # Updates the status and optional failure reason of an existing inbox entry.
                #
                # @param delivery_id [String] unique delivery identifier
                # @param status [Symbol, String] new lifecycle status
                # @param failure_reason [String, nil] optional failure reason
                # @return [Hash, nil] updated entry copy or `nil` if not found
                def update_status(delivery_id:, status:, failure_reason: nil)
                  attrs = {status: status.to_sym}
                  attrs[:failure_reason] = failure_reason if failure_reason
                  update(delivery_id, attrs)
                end

                # Removes an entry by delivery identifier.
                #
                # @param delivery_id [String] unique delivery identifier
                # @return [Boolean] true if the entry was removed
                def delete(delivery_id)
                  result = @redis.del(key_for(delivery_id))
                  result == 1 || result == true
                end

                private

                def key_for(delivery_id)
                  "#{@prefix}#{delivery_id}"
                end

                def extract_delivery_id(entry)
                  id = entry[:delivery_id] || entry["delivery_id"]
                  if id.nil? || id.to_s.strip.empty?
                    raise ArgumentError, "delivery_id is required for inbox persistence"
                  end
                  id.to_s
                end

                def deserialize(raw)
                  entry = JSON.parse(raw, symbolize_names: true)
                  entry[:status] = entry[:status].to_sym if entry[:status]
                  entry
                end
              end
            end
          end
        end
      end
    end
  end
end
