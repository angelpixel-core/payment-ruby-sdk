# frozen_string_literal: true

require "payment/sdk/payments/application/commands/intents/create"
require "payment/sdk/payments/application/commands/intents/confirm"
require "payment/sdk/payments/application/commands/intents/capture"
require "payment/sdk/payments/application/queries/intents/get"
require "payment/sdk/payments/application/queries/charges/get"
require "payment/sdk/payments/application/queries/attempts/get"
require "payment/sdk/payments/application/queries/lifecycles/get"

module Payment
  module SDK
    module Payments
      # Driving interface layer of the payments bounded context.
      module Interfaces
        # Entry point of the payments bounded context.
        #
        # Exposes one resource per aggregate: {#intents}, {#charges}, and {#attempts}.
        class Client
          # @return [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP port used by commands and queries
          attr_reader :http_client

          # @param http_client [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP client port implementation
          def initialize(http_client)
            @http_client = http_client
          end

          # @return [IntentsResource] resource for creating, confirming, capturing, and querying payment intents
          def intents
            @intents ||= IntentsResource.new(@http_client)
          end

          # @return [ChargesResource] resource for querying charges
          def charges
            @charges ||= ChargesResource.new(@http_client)
          end

          # @return [AttemptsResource] resource for querying payment attempts
          def attempts
            @attempts ||= AttemptsResource.new(@http_client)
          end

          # Commands and queries over payment intents.
          class IntentsResource
            # @param http_client [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP client port
            def initialize(http_client)
              @http_client = http_client
            end

            # @param amount [Integer] amount in minor units
            # @param currency [String] 3-letter ISO 4217 currency code
            # @param options [Hash] extra options (`:idempotency_key` is mandatory)
            # @return [Hash] parsed payment intent payload
            def create(amount:, currency:, **options)
              Application::Commands::Intents::Create.new(@http_client).call(
                amount: amount,
                currency: currency,
                **options
              )
            end

            # @param id [String] payment intent identifier
            # @param payment_method_token [String] payment method token
            # @param options [Hash] extra options (`:idempotency_key` is mandatory)
            # @return [Hash] parsed payment intent payload
            def confirm(id, payment_method_token:, **options)
              Application::Commands::Intents::Confirm.new(@http_client).call(
                id: id,
                payment_method_token: payment_method_token,
                **options
              )
            end

            # @param id [String] payment intent identifier
            # @param amount [Integer, nil] amount to capture; `nil` captures the full amount
            # @param options [Hash] extra options (`:idempotency_key` is mandatory)
            # @return [Hash] parsed payment intent payload
            def capture(id, amount: nil, **options)
              Application::Commands::Intents::Capture.new(@http_client).call(
                id: id,
                amount: amount,
                **options
              )
            end

            # @param id [String] payment intent identifier
            # @param options [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
            # @return [Hash] parsed payment intent payload
            def get(id, **options)
              Application::Queries::Intents::Get.new(@http_client).call(id: id, **options)
            end

            # @param id [String] payment intent identifier
            # @param options [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
            # @return [Hash] parsed lifecycle view of the intent
            def get_lifecycle(id, **options)
              Application::Queries::Lifecycles::Get.new(@http_client).call(id: id, **options)
            end
          end

          # Queries over charges.
          class ChargesResource
            # @param http_client [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP client port
            def initialize(http_client)
              @http_client = http_client
            end

            # @param id [String] charge identifier
            # @param options [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
            # @return [Hash] parsed charge payload
            def get(id, **options)
              Application::Queries::Charges::Get.new(@http_client).call(id: id, **options)
            end
          end

          # Queries over payment attempts.
          class AttemptsResource
            # @param http_client [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP client port
            def initialize(http_client)
              @http_client = http_client
            end

            # @param id [String] payment attempt identifier
            # @param options [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
            # @return [Hash] parsed payment attempt payload
            def get(id, **options)
              Application::Queries::Attempts::Get.new(@http_client).call(id: id, **options)
            end
          end
        end
      end
    end
  end
end
