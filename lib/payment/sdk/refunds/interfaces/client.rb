# frozen_string_literal: true

require "payment/sdk/refunds/application/commands/create"
require "payment/sdk/refunds/application/queries/get"

module Payment
  module SDK
    module Refunds
      module Interfaces
        # Entry point of the refunds bounded context.
        class Client
          # @return [#request] HTTP port used by the commands and queries
          attr_reader :http_client

          # @param http_client [#request] implementation of the HTTP client port
          def initialize(http_client)
            @http_client = http_client
          end

          # @param charge_id [String] charge to refund
          # @param amount [Integer, nil] nil refunds the full charge
          # @param options [Hash] `:idempotency_key` is mandatory
          # @return [Domain::Entities::Refund]
          def create(charge_id:, amount: nil, **options)
            Application::Commands::Create.new(@http_client).call(
              charge_id: charge_id,
              amount: amount,
              **options
            )
          end

          # @param id [String] refund id
          # @return [Domain::Entities::Refund]
          def get(id)
            Application::Queries::Get.new(@http_client).call(id: id)
          end
        end
      end
    end
  end
end
