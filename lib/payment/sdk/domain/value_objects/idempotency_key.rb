# frozen_string_literal: true

require "payment/sdk/domain/shared/value_objects/idempotency_key"

module Payment
  module SDK
    module Domain
      module ValueObjects
        IdempotencyKey = Payment::SDK::Domain::Shared::ValueObjects::IdempotencyKey
      end
    end
  end
end
