# frozen_string_literal: true

require "payment/sdk/infrastructure/adapters/http/error_mapper"

module Payment
  module SDK
    module Infrastructure
      module Http
        ErrorMapper = Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper
      end
    end
  end
end
