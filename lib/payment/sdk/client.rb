# frozen_string_literal: true

require "payment/sdk/infrastructure/adapters/http/client/net_http"
require "payment/sdk/infrastructure/adapters/crypto/signature/verifier/hmac_sha256"
require "payment/sdk/infrastructure/adapters/persistence/inbox/store/in_memory"
require "payment/sdk/infrastructure/adapters/persistence/snapshot/store/in_memory"
require "payment/sdk/infrastructure/adapters/reporting/mismatch/reporter/in_memory"

require "payment/sdk/payments/interfaces/client"
require "payment/sdk/refunds/interfaces/client"
require "payment/sdk/webhooks/interfaces/client"
require "payment/sdk/reconciliation/interfaces/client"

module Payment
  module SDK
    # Facade over the four bounded contexts of the SDK
    # (payments, refunds, webhooks and reconciliation).
    #
    # A client is stateless after initialization and safe to share across threads.
    #
    # @example
    #   client = Payment::SDK::Client.new
    #   intent = client.create_payment_intent(amount: 1000, currency: "usd", idempotency_key: "order-1")
    class Client
      # @return [Payment::SDK::Configuration] frozen-in-practice copy of the configuration
      attr_reader :config

      # @param config [Payment::SDK::Configuration] configuration to copy and validate
      # @raise [Payment::SDK::ConfigurationError] when the configuration is invalid
      def initialize(config = Payment::SDK.configuration)
        @config = config.dup
        @config.validate!
      end

      # @return [Payment::SDK::Payments::Interfaces::Client] payments sub-client
      def payments
        @payments ||= Payments::Interfaces::Client.new(http_client)
      end

      # @return [Payment::SDK::Refunds::Interfaces::Client] refunds sub-client
      def refunds
        @refunds ||= Refunds::Interfaces::Client.new(http_client)
      end

      # @return [Payment::SDK::Webhooks::Interfaces::Client] webhooks sub-client
      def webhooks
        @webhooks ||= Webhooks::Interfaces::Client.new(
          secret: @config.signing_secret,
          inbox_store: default_inbox_store,
          verifier: signature_verifier
        )
      end

      # @return [Payment::SDK::Reconciliation::Interfaces::Client] reconciliation sub-client
      def reconciliation
        @reconciliation ||= Reconciliation::Interfaces::Client.new(
          http_client: http_client,
          snapshot_store: default_snapshot_store,
          mismatch_reporter: default_mismatch_reporter
        )
      end

      # Creates a payment intent.
      #
      # @param amount [Integer] amount in minor units (cents)
      # @param currency [String] ISO 4217 currency code
      # @param opts [Hash] extra command options; `:idempotency_key` is mandatory
      # @return [Payment::SDK::Payments::Domain::Entities::PaymentIntent]
      # @raise [ArgumentError] when `:idempotency_key` is missing
      def create_payment_intent(amount:, currency:, **opts)
        payments.intents.create(amount: amount, currency: currency, **opts)
      end

      # Confirms a payment intent with a payment method token.
      #
      # @param id [String] payment intent id (`pi_...`)
      # @param payment_method_token [String]
      # @param opts [Hash] extra command options; `:idempotency_key` is mandatory
      # @return [Payment::SDK::Payments::Domain::Entities::PaymentIntent]
      def confirm_payment_intent(id, payment_method_token:, **opts)
        payments.intents.confirm(id, payment_method_token: payment_method_token, **opts)
      end

      # Captures previously authorized funds.
      #
      # @param id [String] payment intent id
      # @param amount [Integer, nil] amount to capture; nil captures the full amount
      # @param opts [Hash] extra command options; `:idempotency_key` is mandatory
      # @return [Payment::SDK::Payments::Domain::Entities::PaymentIntent]
      def capture_payment_intent(id, amount: nil, **opts)
        payments.intents.capture(id, amount: amount, **opts)
      end

      # Issues a full or partial refund over a charge.
      #
      # @param charge_id [String] charge id (`ch_...`)
      # @param amount [Integer, nil] amount to refund; nil refunds the full charge
      # @param opts [Hash] extra command options; `:idempotency_key` is mandatory
      # @return [Payment::SDK::Refunds::Domain::Entities::Refund]
      def create_refund(charge_id:, amount: nil, **opts)
        refunds.create(charge_id: charge_id, amount: amount, **opts)
      end

      def get_refund(id)
        refunds.get(id)
      end

      def get_payment_intent(id)
        payments.intents.get(id)
      end

      def get_payment_lifecycle(id)
        payments.intents.get_lifecycle(id)
      end

      def get_transaction_report(query_params = {})
        reconciliation.get_report(**query_params)
      end

      def get_transaction_snapshot(query_params = {})
        reconciliation.get_snapshot(**query_params)
      end

      # Verifies, deduplicates (inbox) and projects an incoming webhook.
      #
      # @param payload [String, Hash] raw body or parsed payload
      # @param signature_header [String] value of the signature header
      # @param projection [#call] callable applied to the verified event
      # @param inbox_store [Object, nil] overrides the default inbox store
      # @return [Hash] processing result
      def process_webhook(payload:, signature_header:, projection:, inbox_store: nil)
        webhooks.process(
          payload: payload,
          signature_header: signature_header,
          projection: projection,
          inbox_store: inbox_store
        )
      end

      # Compares local records against the remote snapshot and reports drift.
      #
      # @param local_records [Array<Hash>] local projections to compare
      # @param run_id [String] identifier of the reconciliation run
      # @param snapshot_store [Object, nil] overrides the default snapshot store
      # @param mismatch_reporter [Object, nil] overrides the default mismatch reporter
      # @return [Object] reconciliation result
      def reconcile(local_records:, run_id:, snapshot_store: nil, mismatch_reporter: nil)
        reconciliation.reconcile(
          local_records: local_records,
          run_id: run_id,
          snapshot_store: snapshot_store,
          mismatch_reporter: mismatch_reporter
        )
      end

      private

      def http_client
        @http_client ||= begin
          adapter = Infrastructure::Adapters::Http::Client::NetHttp.new(
            base_url: @config.base_url || "https://api.payment.com",
            open_timeout: @config.open_timeout,
            read_timeout: @config.timeout,
            max_retries: @config.max_retries
          )
          AuthenticatedHttpClient.new(adapter, @config.api_key)
        end
      end

      def signature_verifier
        @signature_verifier ||= Infrastructure::Adapters::Crypto::Signature::Verifier::HmacSha256.new
      end

      def default_inbox_store
        @default_inbox_store ||= Infrastructure::Adapters::Persistence::Inbox::Store::InMemory.new
      end

      def default_snapshot_store
        @default_snapshot_store ||= Infrastructure::Adapters::Persistence::Snapshot::Store::InMemory.new
      end

      def default_mismatch_reporter
        @default_mismatch_reporter ||= Infrastructure::Adapters::Reporting::Mismatch::Reporter::InMemory.new
      end

      def extract_delivery_id(payload)
        parsed = payload.is_a?(String) ? JSON.parse(payload, symbolize_names: true) : payload.transform_keys(&:to_sym)
        parsed[:delivery_id]
      end

      class AuthenticatedHttpClient
        def initialize(adapter, api_key)
          @adapter = adapter
          @api_key = api_key
        end

        def request(method:, path:, headers: {}, body: nil, query_params: {})
          headers["Authorization"] = "Bearer #{@api_key}" if @api_key
          @adapter.request(method: method, path: path, headers: headers, body: body, query_params: query_params)
        end
      end
    end
  end
end
