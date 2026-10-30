# frozen_string_literal: true

require "json"
require "payment/sdk/reconciliation/domain/ports/snapshot/store"

module Payment
  module SDK
    module Infrastructure
      module Adapters
        module Persistence
          module Snapshot
            module Store
              # ActiveRecord-backed reconciliation snapshot adapter implementing
              # {Payment::SDK::Reconciliation::Domain::Ports::Snapshot::Store}.
              #
              # Integrates with any ActiveRecord model class via duck-typing without
              # adding direct gem dependencies.
              class ActiveRecord
                include Payment::SDK::Reconciliation::Domain::Ports::Snapshot::Store

                # @return [Class] underlying ActiveRecord model class
                attr_reader :model_class

                # @param model_class [Class] ActiveRecord model class responding to `#find_or_initialize_by`, `#find_by`, `#all`
                def initialize(model_class:)
                  @model_class = model_class
                end

                # Saves a reconciliation snapshot entry.
                #
                # @param snapshot [Hash, #id] snapshot data
                # @return [Hash] copy of the saved snapshot entry
                def save(snapshot)
                  id = snapshot_id(snapshot)
                  record = find_or_initialize_record(id)

                  assign_attributes(record, snapshot, id)

                  if record.respond_to?(:save!)
                    record.save!
                  else
                    record.save
                  end

                  to_snapshot_hash(record)
                end

                # Finds a stored snapshot by its identifier.
                #
                # @param id [String] snapshot identifier
                # @return [Hash, nil] snapshot entry or `nil` if not found
                def find(id)
                  record = find_record(id)
                  return nil unless record

                  to_snapshot_hash(record)
                end

                # Returns all stored reconciliation snapshot entries.
                #
                # @return [Array<Hash>] list of snapshot entries
                def all
                  records = @model_class.all
                  records.map { |record| to_snapshot_hash(record) }
                end

                # Deletes all snapshot records.
                #
                # @return [void]
                def clear!
                  if @model_class.respond_to?(:delete_all)
                    @model_class.delete_all
                  elsif @model_class.respond_to?(:destroy_all)
                    @model_class.destroy_all
                  end
                end

                private

                def snapshot_id(snapshot)
                  if snapshot.respond_to?(:id)
                    snapshot.id
                  elsif snapshot.respond_to?(:[])
                    snapshot[:id] || snapshot["id"]
                  end
                end

                def find_or_initialize_record(id)
                  if @model_class.respond_to?(:find_or_initialize_by)
                    if model_has_attribute?(:snapshot_id)
                      @model_class.find_or_initialize_by(snapshot_id: id)
                    else
                      @model_class.find_or_initialize_by(id: id)
                    end
                  else
                    find_record(id) || @model_class.new
                  end
                end

                def find_record(id)
                  if @model_class.respond_to?(:find_by)
                    if model_has_attribute?(:snapshot_id)
                      @model_class.find_by(snapshot_id: id)
                    else
                      @model_class.find_by(id: id)
                    end
                  elsif @model_class.respond_to?(:where)
                    col = model_has_attribute?(:snapshot_id) ? :snapshot_id : :id
                    @model_class.where(col => id).first
                  end
                end

                def assign_attributes(record, snapshot, id)
                  hash = snapshot.is_a?(Hash) ? snapshot : snapshot.to_h

                  set_attr(record, :snapshot_id, id) if model_has_attribute?(:snapshot_id)
                  set_attr(record, :id, id) if !model_has_attribute?(:snapshot_id) || record.id.nil?
                  set_attr(record, :run_id, hash[:run_id] || hash["run_id"])
                  set_attr(record, :payment_intent_id, hash[:payment_intent_id] || hash["payment_intent_id"])
                  set_attr(record, :status, (hash[:status] || hash["status"])&.to_s)
                  set_attr(record, :local_data, hash[:local_data] || hash["local_data"])
                  set_attr(record, :remote_data, hash[:remote_data] || hash["remote_data"])
                  set_attr(record, :reconciled_at, hash[:reconciled_at] || hash["reconciled_at"])
                end

                def set_attr(record, attr, value)
                  setter = :"#{attr}="
                  if record.respond_to?(setter)
                    record.public_send(setter, value)
                  elsif record.respond_to?(:[]=)
                    record[attr] = value
                  end
                end

                def model_has_attribute?(attr)
                  if @model_class.respond_to?(:column_names)
                    @model_class.column_names.map(&:to_s).include?(attr.to_s)
                  else
                    true
                  end
                end

                def to_snapshot_hash(record)
                  if record.respond_to?(:to_snapshot_hash)
                    record.to_snapshot_hash
                  else
                    id_val = if record.respond_to?(:snapshot_id) && record.snapshot_id
                      record.snapshot_id
                    elsif record.respond_to?(:id)
                      record.id
                    end

                    status_val = record.respond_to?(:status) ? record.status : nil
                    status_sym = status_val&.to_sym

                    {
                      id: id_val,
                      run_id: record.respond_to?(:run_id) ? record.run_id : nil,
                      payment_intent_id: record.respond_to?(:payment_intent_id) ? record.payment_intent_id : nil,
                      status: status_sym,
                      local_data: normalize_json(record.respond_to?(:local_data) ? record.local_data : nil),
                      remote_data: normalize_json(record.respond_to?(:remote_data) ? record.remote_data : nil),
                      reconciled_at: record.respond_to?(:reconciled_at) ? record.reconciled_at : nil
                    }.compact
                  end
                end

                def normalize_json(value)
                  case value
                  when String
                    begin
                      JSON.parse(value, symbolize_names: true)
                    rescue JSON::ParserError
                      value
                    end
                  when Hash
                    value.transform_keys(&:to_sym)
                  else
                    value
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
