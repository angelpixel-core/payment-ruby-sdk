# frozen_string_literal: true

module Payment
  module SDK
    # Payments bounded context (payment intents, charges, payment attempts, and lifecycles).
    module Payments
      # Domain layer of the payments bounded context.
      module Domain
        # Domain entities and aggregates of the payments bounded context.
        module Entities
          # Aggregate root representing a payment intent and its lifecycle state machine.
          class PaymentIntent
            # @return [String] unique payment intent identifier (`pi_...`)
            attr_reader :id
            # @return [Integer] payment amount in minor currency units
            attr_reader :amount
            # @return [String] 3-letter ISO currency code
            attr_reader :currency
            # @return [Symbol] normalized lifecycle status symbol
            attr_reader :status
            # @return [String] customer identifier
            attr_reader :customer_id
            # @return [String] merchant identifier
            attr_reader :merchant_id
            # @return [String] capture method (`"automatic"` or `"manual"`)
            attr_reader :capture_method
            # @return [String, nil] client secret for client-side confirmation
            attr_reader :client_secret
            # @return [String, Time, nil] creation timestamp
            attr_reader :created_at
            # @return [String, Time, nil] last update timestamp
            attr_reader :updated_at

            # @param id [String] payment intent identifier
            # @param amount [Integer] amount in minor units
            # @param currency [String] currency code
            # @param status [String, Symbol] intent status (normalized to `Symbol`)
            # @param customer_id [String] customer identifier
            # @param merchant_id [String] merchant identifier
            # @param capture_method [String] `"automatic"` or `"manual"`
            # @param client_secret [String, nil] optional client secret
            # @param created_at [String, Time, nil] optional creation timestamp
            # @param updated_at [String, Time, nil] optional update timestamp
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

            # @return [Boolean] `true` when status is `:requires_payment_method`
            def requires_payment_method?
              @status == :requires_payment_method
            end

            # @return [Boolean] `true` when status is `:requires_confirmation`
            def requires_confirmation?
              @status == :requires_confirmation
            end

            # @return [Boolean] `true` when status is `:requires_capture`
            def requires_capture?
              @status == :requires_capture
            end

            # @return [Boolean] `true` when status is `:processing`
            def processing?
              @status == :processing
            end

            # @return [Boolean] `true` when status is `:succeeded`
            def succeeded?
              @status == :succeeded
            end

            # @return [Boolean] `true` when status is `:canceled`
            def canceled?
              @status == :canceled
            end
          end
        end
      end
    end
  end
end
