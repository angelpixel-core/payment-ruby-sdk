# frozen_string_literal: true

module Payment
  module SDK
    module Payments
      module Domain
        module Entities
          class PaymentIntent
            attr_reader :id, :amount, :currency, :status, :customer_id, :merchant_id,
                        :capture_method, :client_secret, :created_at, :updated_at

            def initialize(id:, amount:, currency:, status:, customer_id:, merchant_id:,
                           capture_method: "automatic", client_secret: nil, created_at: nil, updated_at: nil)
              @id = id
              @amount = amount
              @currency = currency
              @status = status.to_sym
              @customer_id = customer_id
              @merchant_id = merchant_id
              @capture_method = capture_method
              @client_secret = client_secret
              @created_at = created_at
              @updated_at = updated_at
              freeze
            end

            def requires_payment_method?
              @status == :requires_payment_method
            end

            def requires_confirmation?
              @status == :requires_confirmation
            end

            def requires_capture?
              @status == :requires_capture
            end

            def processing?
              @status == :processing
            end

            def succeeded?
              @status == :succeeded
            end

            def canceled?
              @status == :canceled
            end
          end
        end
      end
    end
  end
end
