# frozen_string_literal: true

require "payment/sdk/application/shared/base_command"

module Payment
  module SDK
    module Application
      module Refunds
        module Commands
          class Create < Shared::BaseCommand
            def execute(charge_id:, amount:, reason:, idempotency_key:)
              headers = default_headers(idempotency_key)

              body = {
                charge_id: charge_id,
                amount: amount,
                reason: reason
              }

              http_client.request(
                method: :post,
                path: "/refunds",
                headers: headers,
                body: body
              )
            end
          end
        end
      end
    end
  end
end
