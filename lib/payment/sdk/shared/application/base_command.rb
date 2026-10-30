# frozen_string_literal: true

require "payment/sdk/shared/domain/value_objects/idempotency_key"

module Payment
  module SDK
    # Shared kernel containing base classes, value objects, concerns, and ports
    # reused across bounded contexts.
    module Shared
      # Application layer base abstractions for commands and queries.
      module Application
        # Abstract base class for state-mutating CQRS commands.
        #
        # Subclasses must implement {#call} and use {#normalize_idempotency_key}
        # to enforce idempotency on write operations.
        class BaseCommand
          # @return [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP client port
          attr_reader :http_client

          # @param http_client [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP client port
          def initialize(http_client)
            @http_client = http_client
          end

          # Executes the command.
          #
          # @param options [Hash] command keyword arguments
          # @return [Object] command result
          # @raise [NotImplementedError] when not overridden by a subclass
          def call(**options)
            raise NotImplementedError, "#{self.class} must implement #call"
          end

          protected

          # Validates and wraps an idempotency key into a {Domain::ValueObjects::IdempotencyKey}.
          #
          # @param key [String, Domain::ValueObjects::IdempotencyKey] raw key or value object
          # @return [Domain::ValueObjects::IdempotencyKey]
          # @raise [ArgumentError] when `key` is `nil` or blank
          def normalize_idempotency_key(key)
            if key.is_a?(Domain::ValueObjects::IdempotencyKey)
              key
            elsif key.nil? || key.to_s.strip.empty?
              raise ArgumentError, "idempotency_key is required for state-mutating commands"
            else
              Domain::ValueObjects::IdempotencyKey.new(key)
            end
          end

          # Builds standard HTTP headers including idempotency key and distributed tracing.
          #
          # @param idempotency_key [String, Domain::ValueObjects::IdempotencyKey] mandatory idempotency key
          # @param request_id [String, nil] optional correlation identifier
          # @param traceparent [String, nil] optional W3C trace context header
          # @param headers [Hash] additional custom headers
          # @return [Hash{String => String}] merged headers
          # @raise [ArgumentError] when `idempotency_key` is missing or empty
          def build_headers(idempotency_key:, request_id: nil, traceparent: nil, headers: {})
            merged = headers.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v.to_s }
            merged["Idempotency-Key"] = normalize_idempotency_key(idempotency_key).value
            merged["X-Request-Id"] = request_id.to_s if request_id
            merged["traceparent"] = traceparent.to_s if traceparent
            merged
          end
        end
      end
    end
  end
end
