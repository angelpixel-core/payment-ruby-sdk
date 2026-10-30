# frozen_string_literal: true

require "payment/sdk/refunds/application/commands/create"
require "payment/sdk/refunds/application/queries/get"

module Payment
  module SDK
    module Refunds
      # Driving interface layer of the refunds bounded context.
      module Interfaces
        # Entry point of the refunds bounded context.
        class Client
          # @return [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP port used by commands and queries
          attr_reader :http_client

          # @param http_client [Payment::SDK::Shared::Domain::Ports::Http::Client] HTTP client port implementation
          def initialize(http_client)
            @http_client = http_client
          end

          # @param charge_id [String] charge identifier to refund
          # @param amount [Integer, nil] `nil` refunds the full charge
          # @param options [Hash] `:idempotency_key` is mandatory
          # @return [Hash] parsed refund response payload
          def create(charge_id:, amount: nil, **options)
            Application::Commands::Create.new(@http_client).call(
              charge_id: charge_id,
              amount: amount,
              **options
            )
          end

          # @param id [String] refund identifier
          # @param options [Hash] optional query options (`:request_id`, `:traceparent`, etc.)
          # @return [Hash] parsed refund payload
          def get(id, **options)
            Application::Queries::Get.new(@http_client).call(id: id, **options)
          end
        end
      end
    end
  end
end
