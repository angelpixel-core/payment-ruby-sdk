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
      module Interfaces
        # Entry point of the payments bounded context.
        #
        # Exposes one resource per aggregate: {#intents}, {#charges} and {#attempts}.
        class Client
          # @return [#request] HTTP port used by the commands and queries
          attr_reader :http_client

          # @param http_client [#request] implementation of the HTTP client port
          def initialize(http_client)
            @http_client = http_client
          end

          # @return [IntentsResource]
          def intents
            @intents ||= IntentsResource.new(@http_client)
          end

          # @return [ChargesResource]
          def charges
            @charges ||= ChargesResource.new(@http_client)
          end

          # @return [AttemptsResource]
          def attempts
            @attempts ||= AttemptsResource.new(@http_client)
          end

          # Commands and queries over payment intents.
          class IntentsResource
            def initialize(http_client)
              @http_client = http_client
            end

            # @param amount [Integer] amount in minor units
            # @param currency [String] ISO 4217 code
            # @param options [Hash] `:idempotency_key` is mandatory
            # @return [Domain::Entities::PaymentIntent]
            def create(amount:, currency:, **options)
              Application::Commands::Intents::Create.new(@http_client).call(
                amount: amount,
                currency: currency,
                **options
              )
            end

            # @param id [String] payment intent id
            # @param payment_method_token [String]
            # @param options [Hash] `:idempotency_key` is mandatory
            # @return [Domain::Entities::PaymentIntent]
            def confirm(id, payment_method_token:, **options)
              Application::Commands::Intents::Confirm.new(@http_client).call(
                id: id,
                payment_method_token: payment_method_token,
                **options
              )
            end

            # @param id [String] payment intent id
            # @param amount [Integer, nil] nil captures the full amount
            # @param options [Hash] `:idempotency_key` is mandatory
            # @return [Domain::Entities::PaymentIntent]
            def capture(id, amount: nil, **options)
              Application::Commands::Intents::Capture.new(@http_client).call(
                id: id,
                amount: amount,
                **options
              )
            end

            # @param id [String] payment intent id
            # @return [Domain::Entities::PaymentIntent]
            def get(id)
              Application::Queries::Intents::Get.new(@http_client).call(id: id)
            end

            # @param id [String] payment intent id
            # @return [Object] lifecycle view of the intent
            def get_lifecycle(id)
              Application::Queries::Lifecycles::Get.new(@http_client).call(id: id)
            end
          end

          # Queries over charges.
          class ChargesResource
            def initialize(http_client)
              @http_client = http_client
            end

            # @param id [String] charge id
            # @return [Domain::Entities::Charge]
            def get(id)
              Application::Queries::Charges::Get.new(@http_client).call(id: id)
            end
          end

          # Queries over payment attempts.
          class AttemptsResource
            def initialize(http_client)
              @http_client = http_client
            end

            # @param id [String] payment attempt id
            # @return [Domain::Entities::PaymentAttempt]
            def get(id)
              Application::Queries::Attempts::Get.new(@http_client).call(id: id)
            end
          end
        end
      end
    end
  end
end
