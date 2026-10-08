# frozen_string_literal: true

require "payment/sdk/infrastructure/http/net_http_adapter"

require "payment/sdk/application/commands/create_payment_intent"
require "payment/sdk/application/commands/confirm_payment_intent"
require "payment/sdk/application/commands/capture_payment_intent"
require "payment/sdk/application/commands/create_refund"

require "payment/sdk/application/queries/get_payment_intent"
require "payment/sdk/application/queries/get_payment_lifecycle"
require "payment/sdk/application/queries/get_transaction_report"
require "payment/sdk/application/queries/get_transaction_snapshot"

require "payment/sdk/application/use_cases/process_webhook"
require "payment/sdk/application/use_cases/reconcile_transactions"

require "payment/sdk/infrastructure/crypto/hmac_sha256_verifier"
require "payment/sdk/infrastructure/webhooks/event_parser"
require "payment/sdk/infrastructure/persistence/in_memory_inbox_store"
require "payment/sdk/infrastructure/persistence/in_memory_snapshot_store"
require "payment/sdk/infrastructure/reporting/in_memory_mismatch_reporter"

module Payment
  module SDK
    class Client
      attr_reader :config

      def initialize(config = Payment::SDK.configuration)
        @config = config.dup
        @config.validate!
      end

      def create_payment_intent(amount:, currency:, **opts)
        cmd = Application::Commands::CreatePaymentIntent.new(http_client)
        cmd.execute(amount: amount, currency: currency, **opts)
      end

      def confirm_payment_intent(id, payment_method_token:, **opts)
        cmd = Application::Commands::ConfirmPaymentIntent.new(http_client)
        cmd.execute(id: id, payment_method_token: payment_method_token, **opts)
      end

      def capture_payment_intent(id, amount: nil, **opts)
        cmd = Application::Commands::CapturePaymentIntent.new(http_client)
        cmd.execute(id: id, amount: amount, **opts)
      end

      def create_refund(charge_id:, amount: nil, **opts)
        cmd = Application::Commands::CreateRefund.new(http_client)
        cmd.execute(charge_id: charge_id, amount: amount, **opts)
      end

      def get_payment_intent(id)
        query = Application::Queries::GetPaymentIntent.new(http_client)
        query.execute(id: id)
      end

      def get_payment_lifecycle(id)
        query = Application::Queries::GetPaymentLifecycle.new(http_client)
        query.execute(id: id)
      end

      def get_transaction_report(query_params = {})
        query = Application::Queries::GetTransactionReport.new(http_client)
        query.execute(**query_params)
      end

      def get_transaction_snapshot(query_params = {})
        query = Application::Queries::GetTransactionSnapshot.new(http_client)
        query.execute(**query_params)
      end

      def process_webhook(payload:, signature_header:, projection:, inbox_store: default_inbox_store)
        use_case = Application::UseCases::ProcessWebhook.new(
          inbox_store: inbox_store,
          projection: projection,
          verifier: signature_verifier
        )
        use_case.call(
          delivery_id: extract_delivery_id(payload),
          raw_payload: payload.is_a?(String) ? payload : JSON.generate(payload),
          signature_header: signature_header,
          secret: @config.signing_secret
        )
      end

      def reconcile(local_records:, run_id:, snapshot_store: default_snapshot_store, mismatch_reporter: default_mismatch_reporter)
        use_case = Application::UseCases::ReconcileTransactions.new(
          snapshot_client: self,
          snapshot_store: snapshot_store,
          mismatch_reporter: mismatch_reporter
        )
        use_case.call(local_records: local_records, run_id: run_id)
      end

      private

      def http_client
        @http_client ||= begin
          adapter = Infrastructure::Http::NetHttpAdapter.new(
            base_url: @config.base_url || "https://api.payment.com",
            open_timeout: @config.open_timeout,
            read_timeout: @config.timeout,
            max_retries: @config.max_retries
          )
          AuthenticatedHttpClient.new(adapter, @config.api_key)
        end
      end

      def signature_verifier
        @signature_verifier ||= Infrastructure::Crypto::HmacSha256Verifier.new
      end

      def default_inbox_store
        @default_inbox_store ||= Infrastructure::Persistence::InMemoryInboxStore.new
      end

      def default_snapshot_store
        @default_snapshot_store ||= Infrastructure::Persistence::InMemorySnapshotStore.new
      end

      def default_mismatch_reporter
        @default_mismatch_reporter ||= Infrastructure::Reporting::InMemoryMismatchReporter.new
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
