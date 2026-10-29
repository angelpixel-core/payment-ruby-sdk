# frozen_string_literal: true

module Payment
  module SDK
    module Payments
      module Domain
        module Entities
          # Immutable domain entity representing a single execution attempt against a {PaymentIntent}.
          class PaymentAttempt
            # @return [String] unique payment attempt identifier (`pa_...`)
            attr_reader :id
            # @return [String] parent payment intent identifier (`pi_...`)
            attr_reader :payment_intent_id
            # @return [Symbol] normalized attempt status symbol
            attr_reader :status
            # @return [String] payment method type (e.g. `"card"`)
            attr_reader :payment_method_type
            # @return [String, nil] failure error code if the attempt failed
            attr_reader :error_code
            # @return [String, nil] human-readable failure message if the attempt failed
            attr_reader :error_message
            # @return [String, Time, nil] creation timestamp
            attr_reader :created_at

            # @param id [String] payment attempt identifier
            # @param payment_intent_id [String] parent payment intent identifier
            # @param status [String, Symbol] attempt status (normalized to `Symbol`)
            # @param payment_method_type [String] payment method type
            # @param error_code [String, nil] optional error code
            # @param error_message [String, nil] optional error message
            # @param created_at [String, Time, nil] optional creation timestamp
            def initialize(id:, payment_intent_id:, status:, payment_method_type:,
              error_code: nil, error_message: nil, created_at: nil)
              @id = id
              @payment_intent_id = payment_intent_id
              @status = status.to_sym
              @payment_method_type = payment_method_type
              @error_code = error_code
              @error_message = error_message
              @created_at = created_at
              freeze
            end

            # @return [Boolean] `true` when status is `:succeeded` or `:successful`
            def succeeded?
              @status == :succeeded || @status == :successful
            end

            # @return [Boolean] `true` when status is `:failed`
            def failed?
              @status == :failed
            end
          end
        end
      end
    end
  end
end
