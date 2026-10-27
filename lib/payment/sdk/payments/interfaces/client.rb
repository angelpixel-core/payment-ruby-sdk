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
        class Client
          attr_reader :http_client

          def initialize(http_client)
            @http_client = http_client
          end

          def intents
            @intents ||= IntentsResource.new(@http_client)
          end

          def charges
            @charges ||= ChargesResource.new(@http_client)
          end

          def attempts
            @attempts ||= AttemptsResource.new(@http_client)
          end

          class IntentsResource
            def initialize(http_client)
              @http_client = http_client
            end

            def create(amount:, currency:, **options)
              Application::Commands::Intents::Create.new(@http_client).call(
                amount: amount,
                currency: currency,
                **options
              )
            end

            def confirm(id, payment_method_token:, **options)
              Application::Commands::Intents::Confirm.new(@http_client).call(
                id: id,
                payment_method_token: payment_method_token,
                **options
              )
            end

            def capture(id, amount: nil, **options)
              Application::Commands::Intents::Capture.new(@http_client).call(
                id: id,
                amount: amount,
                **options
              )
            end

            def get(id)
              Application::Queries::Intents::Get.new(@http_client).call(id: id)
            end

            def get_lifecycle(id)
              Application::Queries::Lifecycles::Get.new(@http_client).call(id: id)
            end
          end

          class ChargesResource
            def initialize(http_client)
              @http_client = http_client
            end

            def get(id)
              Application::Queries::Charges::Get.new(@http_client).call(id: id)
            end
          end

          class AttemptsResource
            def initialize(http_client)
              @http_client = http_client
            end

            def get(id)
              Application::Queries::Attempts::Get.new(@http_client).call(id: id)
            end
          end
        end
      end
    end
  end
end
