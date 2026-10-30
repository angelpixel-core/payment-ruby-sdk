# frozen_string_literal: true

require_relative "payment/sdk/version"
require_relative "payment/sdk/configuration"
require_relative "payment/sdk/client"

# Top-level namespace for the Payment Ruby SDK.
module Payment
  # Core namespace of the Payment SDK.
  #
  # Provides global configuration helpers ({.configuration}, {.configure}, {.reset_configuration!})
  # and the root facade {Payment::SDK::Client}.
  module SDK
    class << self
      # Returns the global SDK configuration instance.
      #
      # @return [Payment::SDK::Configuration]
      def configuration
        @configuration ||= Configuration.new
      end

      # Yields the global configuration to a block and validates it afterwards.
      #
      # @yieldparam config [Payment::SDK::Configuration]
      # @return [Payment::SDK::Configuration]
      # @raise [ArgumentError] when any timeout or retry setting is invalid
      def configure
        yield(configuration) if block_given?
        configuration.validate!
        configuration
      end

      # Resets the global configuration back to a fresh {Payment::SDK::Configuration} instance.
      #
      # @return [Payment::SDK::Configuration]
      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end
