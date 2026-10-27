# frozen_string_literal: true

module Payment
  module SDK
    module Domain
      module Webhooks
        module Ports
          module Inbox
            module Store
              def find_by_delivery_id(delivery_id)
                raise NotImplementedError, "#{self.class} must implement #find_by_delivery_id"
              end

              def persist(entry)
                raise NotImplementedError, "#{self.class} must implement #persist"
              end

              def update(delivery_id, attributes)
                raise NotImplementedError, "#{self.class} must implement #update"
              end
            end
          end
        end
      end
    end
  end
end
