# frozen_string_literal: true

require "payment/sdk/errors"

module Payment
  module SDK
    module Infrastructure
      # Infrastructure resilience patterns such as Circuit Breaker, Rate Limiter, and Retry Policies.
      module Resilience
        # Thread-safe implementation of the Circuit Breaker pattern.
        #
        # States:
        # - `:closed`: Normal operations. Requests pass through to upstream. Consecutive failures are tracked.
        # - `:open`: Failure threshold reached. Outgoing requests are rejected immediately with
        #   {Payment::SDK::CircuitBreakerOpenError} without making network calls.
        # - `:half_open`: After `reset_timeout` elapses, a probe request is permitted. If successful,
        #   the circuit closes; if it fails, the circuit reopens immediately.
        class CircuitBreaker
          # Closed state: normal request execution.
          STATE_CLOSED = :closed
          # Open state: upstream requests are paused and fail immediately.
          STATE_OPEN = :open
          # Half-open state: a probe request is permitted to test upstream health.
          STATE_HALF_OPEN = :half_open

          # @return [Symbol] current state (`:closed`, `:open`, `:half_open`)
          attr_reader :state
          # @return [Integer] current number of consecutive tracked failures
          attr_reader :failure_count
          # @return [Numeric, nil] monotonic timestamp of the last recorded failure
          attr_reader :last_failure_time
          # @return [Integer] maximum consecutive failures before tripping to `:open`
          attr_reader :failure_threshold
          # @return [Numeric] cooldown period in seconds before attempting `:half_open` probe
          attr_reader :reset_timeout

          # @param failure_threshold [Integer] consecutive failure count to trip the circuit (default: 5)
          # @param reset_timeout [Numeric] duration in seconds before half-open probe (default: 30)
          def initialize(failure_threshold: 5, reset_timeout: 30)
            @failure_threshold = failure_threshold
            @reset_timeout = reset_timeout
            @state = STATE_CLOSED
            @failure_count = 0
            @last_failure_time = nil
            @mutex = Mutex.new
          end

          # Validates whether an outgoing request can proceed according to the circuit state.
          #
          # @return [void]
          # @raise [Payment::SDK::CircuitBreakerOpenError] when state is `:open` and reset timeout has not elapsed
          def check!
            @mutex.synchronize do
              if @state == STATE_OPEN
                if clock_now - @last_failure_time >= @reset_timeout
                  @state = STATE_HALF_OPEN
                else
                  raise Payment::SDK::CircuitBreakerOpenError.new(
                    "Circuit breaker is OPEN. Upstream requests are temporarily paused for #{@reset_timeout}s.",
                    reset_timeout: @reset_timeout,
                    state: :open
                  )
                end
              end
            end
          end

          # Records a successful upstream request. In `:half_open` or `:closed`, resets failures and closes circuit.
          #
          # @return [void]
          def record_success!
            @mutex.synchronize do
              @state = STATE_CLOSED
              @failure_count = 0
              @last_failure_time = nil
            end
          end

          # Records an infrastructure/upstream failure (timeouts, socket errors, HTTP 5xx).
          # Trips the circuit to `:open` when failure threshold is reached or when failing in `:half_open`.
          #
          # @return [void]
          def record_failure!
            @mutex.synchronize do
              @failure_count += 1
              @last_failure_time = clock_now

              if @state == STATE_HALF_OPEN || @failure_count >= @failure_threshold
                @state = STATE_OPEN
              end
            end
          end

          # Resets the circuit breaker state to `:closed` and clears all counters.
          #
          # @return [void]
          def reset!
            @mutex.synchronize do
              @state = STATE_CLOSED
              @failure_count = 0
              @last_failure_time = nil
            end
          end

          # @return [Boolean] `true` if state is `:closed`
          def closed?
            @mutex.synchronize { @state == STATE_CLOSED }
          end

          # @return [Boolean] `true` if state is `:open`
          def open?
            @mutex.synchronize { @state == STATE_OPEN }
          end

          # @return [Boolean] `true` if state is `:half_open`
          def half_open?
            @mutex.synchronize { @state == STATE_HALF_OPEN }
          end

          private

          def clock_now
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end
        end
      end
    end
  end
end
