# frozen_string_literal: true

require "test_helper"
require "payment/sdk/infrastructure/resilience/circuit_breaker"

class InfrastructureResilienceCircuitBreakerTest < Minitest::Test
  def setup
    @cb = Payment::SDK::Infrastructure::Resilience::CircuitBreaker.new(
      failure_threshold: 3,
      reset_timeout: 0.1
    )
  end

  def test_initial_state_is_closed
    assert @cb.closed?
    refute @cb.open?
    refute @cb.half_open?
    assert_equal 0, @cb.failure_count
    assert_nil @cb.last_failure_time

    # check! does not raise in closed state
    assert_nil @cb.check!
  end

  def test_trips_to_open_after_reaching_failure_threshold
    @cb.record_failure!
    assert @cb.closed?
    assert_equal 1, @cb.failure_count

    @cb.record_failure!
    assert @cb.closed?
    assert_equal 2, @cb.failure_count

    @cb.record_failure!
    assert @cb.open?
    refute @cb.closed?
    assert_equal 3, @cb.failure_count
  end

  def test_open_circuit_raises_circuit_breaker_open_error
    3.times { @cb.record_failure! }
    assert @cb.open?

    error = assert_raises(Payment::SDK::CircuitBreakerOpenError) do
      @cb.check!
    end

    assert_includes error.message, "Circuit breaker is OPEN"
    assert_equal :open, error.state
    assert_equal 0.1, error.reset_timeout
  end

  def test_half_open_transition_and_recovery
    3.times { @cb.record_failure! }
    assert @cb.open?

    # Wait for reset_timeout
    sleep 0.15

    # check! transitions to half_open and allows the request
    @cb.check!
    assert @cb.half_open?

    # Successful probe closes the circuit
    @cb.record_success!
    assert @cb.closed?
    assert_equal 0, @cb.failure_count
  end

  def test_half_open_failure_reopens_immediately
    3.times { @cb.record_failure! }
    sleep 0.15

    @cb.check!
    assert @cb.half_open?

    # Failed probe reopens immediately
    @cb.record_failure!
    assert @cb.open?
  end

  def test_reset_method_clears_state
    3.times { @cb.record_failure! }
    assert @cb.open?

    @cb.reset!
    assert @cb.closed?
    assert_equal 0, @cb.failure_count
    assert_nil @cb.last_failure_time
  end

  def test_thread_safety_under_concurrent_failures
    threads = 10.times.map do
      Thread.new do
        @cb.record_failure!
      end
    end
    threads.each(&:join)

    assert @cb.open?
    assert_equal 10, @cb.failure_count
  end
end
