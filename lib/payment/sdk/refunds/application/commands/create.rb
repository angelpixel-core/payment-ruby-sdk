# frozen_string_literal: true

require "payment/sdk/shared/application/base_command"

module Payment
  module SDK
    module Refunds
      module Application
        module Commands
          class Create < Shared::Application::BaseCommand
            def call(charge_id:, amount: nil, reason: nil, idempotency_key: nil)
              key = normalize_idempotency_key(idempotency_key)

              headers = {
                "Idempotency-Key" => key.value
              }

              body = {
                charge_id: charge_id
              }
              body[:amount] = amount if amount
              body[:reason] = reason if reason

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
