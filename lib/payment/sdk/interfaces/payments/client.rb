# frozen_string_literal: true

require "payment/sdk/application/payments/commands/intents/create"
require "payment/sdk/application/payments/commands/intents/confirm"
require "payment/sdk/application/payments/commands/intents/capture"
require "payment/sdk/application/payments/queries/intents/get"
require "payment/sdk/application/payments/queries/charges/get"
require "payment/sdk/application/payments/queries/attempts/get"
require "payment/sdk/application/payments/queries/lifecycles/get"

module Payment
  module SDK
    module Interfaces
      module Payments
        class Client
          attr_reader :http_client

          def initialize(http_client)
            @http_client = http_client
          end

          def intents
            @intents ||= IntentsResource.new(http_client)
          end

          def charges
            @charges ||= ChargesResource.new(http_client)
          end

          def attempts
            @attempts ||= AttemptsResource.new(http_client)
          end

          class IntentsResource
            def initialize(http_client)
              @http_client = http_client
            end

            def create(amount:, currency:, **opts)
              Application::Payments::Commands::Intents::Create.new(@http_client).execute(
                amount: amount,
                currency: currency,
                **opts
              )
            end

            def confirm(id, payment_method_token:, idempotency_key:, scenario: nil)
              Application::Payments::Commands::Intents::Confirm.new(@http_client).execute(
                id: id,
                payment_method_token: payment_method_token,
                idempotency_key: idempotency_key,
                scenario: scenario
              )
            end

            def capture(id, amount:, idempotency_key:)
              Application::Payments::Commands::Intents::Capture.new(@http_client).execute(
                id: id,
                amount: amount,
                idempotency_key: idempotency_key
              )
            end

            def get(id)
              Application::Payments::Queries::Intents::Get.new(@http_client).execute(id: id)
            end

            def get_lifecycle(id)
              Application::Payments::Queries::Lifecycles::Get.new(@http_client).execute(id: id)
            end
          end

          class ChargesResource
            def initialize(http_client)
              @http_client = http_client
            end

            def get(id)
              Application::Payments::Queries::Charges::Get.new(@http_client).execute(id: id)
            end
          end

          class AttemptsResource
            def initialize(http_client)
              @http_client = http_client
            end

            def get(id)
              Application::Payments::Queries::Attempts::Get.new(@http_client).execute(id: id)
            end
          end
        end
      end
    end
  end
end
