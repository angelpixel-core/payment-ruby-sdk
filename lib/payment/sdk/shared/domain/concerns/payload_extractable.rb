# frozen_string_literal: true

module Payment
  module SDK
    module Shared
      module Domain
        module Concerns
          module PayloadExtractable
            def extract_prefixed_id(prefix, fallback_key)
              return nil unless respond_to?(:data) && data.is_a?(Hash)

              object_id = data.dig(:object, :id) || data.dig("object", "id")
              return object_id if object_id && object_id.to_s.start_with?(prefix)

              data[fallback_key.to_sym] || data[fallback_key.to_s]
            end
          end
        end
      end
    end
  end
end
