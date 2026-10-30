# frozen_string_literal: true

module Payment
  module SDK
    module Shared
      # Domain layer of the shared kernel.
      module Domain
        # Reusable domain mixins.
        module Concerns
          # Composable concern for extracting prefixed entity identifiers
          # (such as `pi_`, `ch_`, `re_`) from nested event `data` hashes.
          module PayloadExtractable
            # Extracts an identifier with the given prefix from `data[:object][:id]`
            # or falls back to `data[fallback_key]`.
            #
            # @param prefix [String] expected identifier prefix (e.g. `"pi_"`, `"ch_"`, `"re_"`)
            # @param fallback_key [Symbol, String] root key inside `data` to inspect as fallback
            # @return [String, nil] matching identifier or `nil`
            def extract_prefixed_id(prefix, fallback_key)
              return nil unless respond_to?(:data) && data.is_a?(Hash)

              object_id = data.dig(:object, :id) || data.dig("object", "id")
              return object_id if object_id&.to_s&.start_with?(prefix)

              data[fallback_key.to_sym] || data[fallback_key.to_s]
            end
          end
        end
      end
    end
  end
end
