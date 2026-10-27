# frozen_string_literal: true

module Payment
  module SDK
    module Webhooks
      module Domain
        module Ports
          module Inbox
            module Store
              def save(entry)
                raise NotImplementedError, "#{self.class} must implement #save"
              end

              def find_by_delivery_id(delivery_id)
                raise NotImplementedError, "#{self.class} must implement #find_by_delivery_id"
              end

              def update_status(delivery_id:, status:, failure_reason: nil)
                raise NotImplementedError, "#{self.class} must implement #update_status"
              end
            end
          end
        end
      end
    end
  end
end
