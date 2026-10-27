# frozen_string_literal: true

require "payment/sdk/application/refunds/commands/create"
require "payment/sdk/application/refunds/queries/get"

module Payment
  module SDK
    module Interfaces
      module Refunds
        class Client
          attr_reader :http_client

          def initialize(http_client)
            @http_client = http_client
          end

          def create(charge_id:, amount:, reason:, idempotency_key:)
            Application::Refunds::Commands::Create.new(@http_client).execute(
              charge_id: charge_id,
              amount: amount,
              reason: reason,
              idempotency_key: idempotency_key
            )
          end

          def get(id)
            Application::Refunds::Queries::Get.new(@http_client).execute(id: id)
          end
        end
      end
    end
  end
end
