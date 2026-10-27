# frozen_string_literal: true

require "payment/sdk/refunds/application/commands/create"
require "payment/sdk/refunds/application/queries/get"

module Payment
  module SDK
    module Refunds
      module Interfaces
        class Client
          attr_reader :http_client

          def initialize(http_client)
            @http_client = http_client
          end

          def create(charge_id:, amount: nil, **options)
            Application::Commands::Create.new(@http_client).call(
              charge_id: charge_id,
              amount: amount,
              **options
            )
          end

          def get(id)
            Application::Queries::Get.new(@http_client).call(id: id)
          end
        end
      end
    end
  end
end
