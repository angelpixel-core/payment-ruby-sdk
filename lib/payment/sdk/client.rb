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
    class Client
      attr_reader :config

      def initialize(config = Payment::SDK.configuration)
        @config = config.dup
        @config.validate!
      end

      def payments
        @payments ||= Payments::Interfaces::Client.new(http_client)
      end

      def refunds
        @refunds ||= Refunds::Interfaces::Client.new(http_client)
      end

      def webhooks
        @webhooks ||= Webhooks::Interfaces::Client.new(
          secret: @config.signing_secret,
          inbox_store: default_inbox_store,
          verifier: signature_verifier
        )
      end

      def reconciliation
        @reconciliation ||= Reconciliation::Interfaces::Client.new(
          http_client: http_client,
          snapshot_store: default_snapshot_store,
          mismatch_reporter: default_mismatch_reporter
        )
      end

      def create_payment_intent(amount:, currency:, **opts)
        payments.intents.create(amount: amount, currency: currency, **opts)
      end

      def confirm_payment_intent(id, payment_method_token:, **opts)
        payments.intents.confirm(id, payment_method_token: payment_method_token, **opts)
      end

      def capture_payment_intent(id, amount: nil, **opts)
        payments.intents.capture(id, amount: amount, **opts)
      end

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

      def process_webhook(payload:, signature_header:, projection:, inbox_store: nil)
        webhooks.process(
          payload: payload,
          signature_header: signature_header,
          projection: projection,
          inbox_store: inbox_store
        )
      end

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
