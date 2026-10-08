# frozen_string_literal: true

require_relative "payment/sdk/version"
require_relative "payment/sdk/configuration"

module Payment
  module SDK
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration) if block_given?
        configuration.validate!
        configuration
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end
