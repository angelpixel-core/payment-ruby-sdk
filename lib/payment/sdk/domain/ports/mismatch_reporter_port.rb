# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Ports
        module MismatchReporterPort
          def report(snapshot:)
            raise NotImplementedError, "#{self.class} must implement #report"
          end
        end
      end
    end
  end
end
