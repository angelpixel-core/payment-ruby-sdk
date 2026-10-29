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
    # ({#payments}, {#refunds}, {#webhooks}, and {#reconciliation}).
    #
    # A client duplicates and validates its configuration upon initialization
    # and is safe to share across threads.
    #
    # @example
    #   client = Payment::SDK::Client.new
    #   intent = client.create_payment_intent(amount: 1000, currency: "usd", idempotency_key: "order-1")
    class Client
      # @return [Payment::SDK::Configuration] validated copy of the client configuration
      attr_reader :config

      # @param config [Payment::SDK::Configuration] configuration to duplicate and validate
      # @raise [ArgumentError] when the configuration has invalid timeout or retry values
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
      # @param currency [String] 3-letter ISO 4217 currency code
      # @param opts [Hash] extra command options; `:idempotency_key` is mandatory
      # @return [Hash] parsed response payload from the API
      # @raise [ArgumentError] when `:idempotency_key` is missing or amount/currency is invalid
      def create_payment_intent(amount:, currency:, **opts)
        payments.intents.create(amount: amount, currency: currency, **opts)
      end

      # Confirms a payment intent with a payment method token.
      #
      # @param id [String] payment intent identifier (`pi_...`)
      # @param payment_method_token [String] payment method token
      # @param opts [Hash] extra command options; `:idempotency_key` is mandatory
      # @return [Hash] parsed response payload from the API
      def confirm_payment_intent(id, payment_method_token:, **opts)
        payments.intents.confirm(id, payment_method_token: payment_method_token, **opts)
      end

      # Captures previously authorized funds for a payment intent.
      #
      # @param id [String] payment intent identifier
      # @param amount [Integer, nil] amount to capture; `nil` captures the full amount
      # @param opts [Hash] extra command options; `:idempotency_key` is mandatory
      # @return [Hash] parsed response payload from the API
      def capture_payment_intent(id, amount: nil, **opts)
        payments.intents.capture(id, amount: amount, **opts)
      end

      # Issues a full or partial refund over a charge.
      #
      # @param charge_id [String] charge identifier (`ch_...`)
      # @param amount [Integer, nil] amount to refund; `nil` refunds the full charge
      # @param opts [Hash] extra command options; `:idempotency_key` is mandatory
      # @return [Hash] parsed response payload from the API
      def create_refund(charge_id:, amount: nil, **opts)
        refunds.create(charge_id: charge_id, amount: amount, **opts)
      end

      # Retrieves a refund by its identifier.
      #
      # @param id [String] refund identifier (`re_...`)
      # @param opts [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
      # @return [Hash] parsed refund payload
      def get_refund(id, **opts)
        refunds.get(id, **opts)
      end

      # Retrieves a payment intent by its identifier.
      #
      # @param id [String] payment intent identifier (`pi_...`)
      # @param opts [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
      # @return [Hash] parsed payment intent payload
      def get_payment_intent(id, **opts)
        payments.intents.get(id, **opts)
      end

      # Retrieves the aggregated lifecycle view of a payment intent.
      #
      # @param id [String] payment intent identifier (`pi_...`)
      # @param opts [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
      # @return [Hash] parsed lifecycle payload
      def get_payment_lifecycle(id, **opts)
        payments.intents.get_lifecycle(id, **opts)
      end

      # Retrieves a canonical transaction report.
      #
      # @param query_params [Hash] optional `:start_date` and `:end_date` filters
      # @param opts [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
      # @return [Array<Hash>, Hash] parsed report payload
      def get_transaction_report(query_params = {}, **opts)
        reconciliation.get_report(**query_params, **opts)
      end

      # Retrieves a deterministic transaction snapshot for reconciliation.
      #
      # @param query_params [Hash] optional `:start_date` and `:end_date` filters
      # @param opts [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
      # @return [Array<Hash>, Hash] parsed snapshot payload
      def get_transaction_snapshot(query_params = {}, **opts)
        reconciliation.get_snapshot(**query_params, **opts)
      end

      # Verifies, deduplicates (inbox), and projects an incoming webhook.
      #
      # @param payload [String, Hash] raw JSON string or parsed hash payload
      # @param signature_header [String] value of the webhook signature header
      # @param projection [#apply!] projection object responding to `#apply!(inbox_entry:)`
      # @param inbox_store [Payment::SDK::Webhooks::Domain::Ports::Inbox::Store, nil] custom inbox store
      # @return [Hash] processing status (`:processed` or `:duplicate`) and inbox entry
      def process_webhook(payload:, signature_header:, projection:, inbox_store: nil)
        webhooks.process(
          payload: payload,
          signature_header: signature_header,
          projection: projection,
          inbox_store: inbox_store
        )
      end

      # Compares local records against the remote snapshot and reports any drift.
      #
      # @param local_records [Array<Hash>] local records to compare
      # @param run_id [String] unique identifier of the reconciliation run
      # @param snapshot_store [Payment::SDK::Reconciliation::Domain::Ports::Snapshot::Store, nil] custom snapshot store
      # @param mismatch_reporter [Payment::SDK::Reconciliation::Domain::Ports::Mismatch::Reporter, nil] custom mismatch reporter
      # @return [Array<Hash>] list of reconciliation snapshot entries
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
            max_retries: @config.max_retries,
            logger: @config.logger
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

      # Internal decorator that injects the `Authorization: Bearer <api_key>` header
      # into outgoing HTTP requests.
      class AuthenticatedHttpClient
        # @param adapter [Payment::SDK::Shared::Domain::Ports::Http::Client] underlying HTTP adapter
        # @param api_key [String, nil] bearer API key
        def initialize(adapter, api_key)
          @adapter = adapter
          @api_key = api_key
        end

        # Performs an authenticated HTTP request.
        #
        # @param method [Symbol, String] HTTP verb (`:get`, `:post`, `:put`, `:delete`)
        # @param path [String] request path starting with `/`
        # @param headers [Hash] custom HTTP headers
        # @param body [Hash, nil] request body payload
        # @param query_params [Hash] URL query string parameters
        # @param request_id [String, nil] optional correlation identifier for `X-Request-Id`
        # @param traceparent [String, nil] optional W3C trace context header
        # @return [Object] parsed response body
        def request(method:, path:, headers: {}, body: nil, query_params: {}, request_id: nil, traceparent: nil)
          headers["Authorization"] = "Bearer #{@api_key}" if @api_key
          @adapter.request(
            method: method,
            path: path,
            headers: headers,
            body: body,
            query_params: query_params,
            request_id: request_id,
            traceparent: traceparent
          )
        end
      end
    end
  end
end
