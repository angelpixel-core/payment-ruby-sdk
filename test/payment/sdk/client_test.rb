# frozen_string_literal: true

require "test_helper"
require "payment/sdk/client"

class ClientTest < Minitest::Test
  def setup
    @config = Payment::SDK::Configuration.new
    @config.api_key = "sk_test_key"
    @config.signing_secret = "whsec_secret"
    @client = Payment::SDK::Client.new(@config)
  end

  def test_sub_clients_are_accessible_and_memoized
    assert_instance_of Payment::SDK::Interfaces::Payments::Client, @client.payments
    assert_same @client.payments, @client.payments

    assert_instance_of Payment::SDK::Interfaces::Refunds::Client, @client.refunds
    assert_same @client.refunds, @client.refunds

    assert_instance_of Payment::SDK::Interfaces::Webhooks::Client, @client.webhooks
    assert_same @client.webhooks, @client.webhooks

    assert_instance_of Payment::SDK::Interfaces::Reconciliation::Client, @client.reconciliation
    assert_same @client.reconciliation, @client.reconciliation
  end

  def test_initialization_validates_configuration
    invalid_config = Payment::SDK::Configuration.new
    invalid_config.timeout = -1
    assert_raises(ArgumentError) do
      Payment::SDK::Client.new(invalid_config)
    end
  end

  def test_delegated_methods_forward_to_sub_clients
    # Test delegation by stubbing sub-clients
    payments_mock = Object.new
    def payments_mock.intents
      @intents ||= Struct.new(:dummy) do
        def create(**opts); { delegated: :create_intent, opts: opts }; end
        def confirm(id, **opts); { delegated: :confirm_intent, id: id, opts: opts }; end
        def capture(id, **opts); { delegated: :capture_intent, id: id, opts: opts }; end
        def get(id); { delegated: :get_intent, id: id }; end
        def get_lifecycle(id); { delegated: :get_lifecycle, id: id }; end
      end.new(nil)
    end
    @client.instance_variable_set(:@payments, payments_mock)

    assert_equal :create_intent, @client.create_payment_intent(amount: 100, currency: "usd")[:delegated]
    assert_equal :confirm_intent, @client.confirm_payment_intent("pi_1", payment_method_token: "pm_tok")[:delegated]
    assert_equal :capture_intent, @client.capture_payment_intent("pi_1")[:delegated]
    assert_equal :get_intent, @client.get_payment_intent("pi_1")[:delegated]
    assert_equal :get_lifecycle, @client.get_payment_lifecycle("pi_1")[:delegated]

    refunds_mock = Object.new
    def refunds_mock.create(**opts); { delegated: :create_refund, opts: opts }; end
    def refunds_mock.get(id); { delegated: :get_refund, id: id }; end
    @client.instance_variable_set(:@refunds, refunds_mock)

    assert_equal :create_refund, @client.create_refund(charge_id: "ch_1")[:delegated]
    assert_equal :get_refund, @client.get_refund("re_1")[:delegated]

    webhooks_mock = Object.new
    def webhooks_mock.process(**opts); { delegated: :process_webhook, opts: opts }; end
    @client.instance_variable_set(:@webhooks, webhooks_mock)

    assert_equal :process_webhook, @client.process_webhook(payload: "{}", signature_header: "sig", projection: nil)[:delegated]

    reconciliation_mock = Object.new
    def reconciliation_mock.get_report(**opts); { delegated: :get_report, opts: opts }; end
    def reconciliation_mock.get_snapshot(**opts); { delegated: :get_snapshot, opts: opts }; end
    def reconciliation_mock.reconcile(**opts); { delegated: :reconcile, opts: opts }; end
    @client.instance_variable_set(:@reconciliation, reconciliation_mock)

    assert_equal :get_report, @client.get_transaction_report[:delegated]
    assert_equal :get_snapshot, @client.get_transaction_snapshot[:delegated]
    assert_equal :reconcile, @client.reconcile(local_records: [], run_id: "run_1")[:delegated]
  end
end
