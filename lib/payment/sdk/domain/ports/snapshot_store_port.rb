# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Ports
        module SnapshotStorePort
          def save(snapshot)
            raise NotImplementedError, "#{self.class} must implement #save"
          end

          def find(id)
            raise NotImplementedError, "#{self.class} must implement #find"
          end

          def all
            raise NotImplementedError, "#{self.class} must implement #all"
          end
        end
      end
    end
  end
end
