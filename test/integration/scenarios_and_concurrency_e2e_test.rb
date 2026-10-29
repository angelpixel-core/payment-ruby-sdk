# frozen_string_literal: true

require "integration_helper"
require "securerandom"

class ScenariosAndConcurrencyE2ETest < Payment::IntegrationTest
  def test_idempotency_replay_returns_identical_intent
    idempotency_key = "e2e_idem_replay_#{SecureRandom.hex(6)}"

    res1 = client.create_payment_intent(
      amount: 4500,
      currency: "usd",
      capture_method: "automatic",
      idempotency_key: idempotency_key
    )

    intent1 = res1[:payment_intent] || res1
    refute_nil intent1[:id]

    res2 = client.create_payment_intent(
      amount: 4500,
      currency: "usd",
      capture_method: "automatic",
      idempotency_key: idempotency_key
    )

    intent2 = res2[:payment_intent] || res2
    assert_equal intent1[:id], intent2[:id]
    assert_equal intent1[:amount], intent2[:amount]
  end

  def test_declined_scenario_raises_api_error
    intent_res = client.create_payment_intent(
      amount: 7000,
      currency: "usd",
      capture_method: "automatic",
      idempotency_key: "e2e_decline_#{SecureRandom.hex(6)}"
    )

    intent_id = (intent_res[:payment_intent] || intent_res)[:id]

    assert_raises(Payment::SDK::PaymentDeclinedError, Payment::SDK::ApiError) do
      client.confirm_payment_intent(
        intent_id,
        payment_method_token: "pm_card_declined",
        scenario: "declined",
        idempotency_key: "e2e_decline_conf_#{SecureRandom.hex(6)}"
      )
    end
  end

  def test_multithreaded_concurrency_against_sandbox
    concurrency = 6
    threads = []
    results = ConcurrentArray.new

    concurrency.times do |i|
      threads << Thread.new do
        create_res = client.create_payment_intent(
          amount: 1000 + (i * 100),
          currency: "usd",
          capture_method: "automatic",
          idempotency_key: "e2e_thread_#{i}_#{SecureRandom.hex(6)}"
        )
        intent_id = (create_res[:payment_intent] || create_res)[:id]

        confirm_res = client.confirm_payment_intent(
          intent_id,
          payment_method_token: "pm_card_visa",
          idempotency_key: "e2e_thread_conf_#{i}_#{SecureRandom.hex(6)}"
        )
        status = (confirm_res[:payment_intent] || confirm_res)[:status]
        results << status
      end
    end

    threads.each(&:join)

    assert_equal concurrency, results.size
    results.each do |st|
      assert_equal "succeeded", st
    end
  end

  class ConcurrentArray
    def initialize
      @array = []
      @mutex = Mutex.new
    end

    def <<(item)
      @mutex.synchronize { @array << item }
    end

    def size
      @mutex.synchronize { @array.size }
    end

    def each(&block)
      @mutex.synchronize { @array.each(&block) }
    end
  end
end
