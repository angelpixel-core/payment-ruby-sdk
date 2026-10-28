# frozen_string_literal: true

module Payment
  module SDK
    module Reconciliation
      module Application
        # Use cases of the reconciliation bounded context.
        module UseCases
          # Compares local transaction records against the remote platform snapshot,
          # persists per-intent reconciliation snapshots, and reports any drift.
          class Reconcile
            # @param snapshot_client [#get_transaction_snapshot, #get_snapshot] client used to fetch remote records
            # @param snapshot_store [Domain::Ports::Snapshot::Store] store where reconciliation snapshots are persisted
            # @param mismatch_reporter [Domain::Ports::Mismatch::Reporter] reporter notified when drift is detected
            def initialize(snapshot_client:, snapshot_store:, mismatch_reporter:)
              @snapshot_client = snapshot_client
              @snapshot_store = snapshot_store
              @mismatch_reporter = mismatch_reporter
            end

            # Runs reconciliation for the given local records and run identifier.
            #
            # @param local_records [Array<Hash>] local records to reconcile
            # @param run_id [String] unique reconciliation run identifier
            # @return [Array<Hash>] reconciliation snapshot entries for all compared records
            def call(local_records:, run_id:)
              local_records = local_records.map(&:dup)
              remote_records = fetch_remote_records

              local_map = local_records.to_h { |r| [record_id(r), r] }
              remote_map = remote_records.to_h { |r| [record_id(r), r] }

              all_ids = (local_map.keys + remote_map.keys).uniq

              results = all_ids.map do |id|
                local = local_map[id]
                remote = remote_map[id]

                status = determine_drift_status(local, remote)

                snapshot = {
                  id: "#{run_id}:#{id}",
                  run_id: run_id,
                  payment_intent_id: id,
                  status: status,
                  local_data: local,
                  remote_data: remote,
                  reconciled_at: Time.now.utc
                }

                @snapshot_store.save(snapshot)
                @mismatch_reporter.report(snapshot: snapshot)

                snapshot
              end

              results
            end

            private

            def fetch_remote_records
              if @snapshot_client.respond_to?(:get_transaction_snapshot)
                @snapshot_client.get_transaction_snapshot
              elsif @snapshot_client.respond_to?(:get_snapshot)
                @snapshot_client.get_snapshot
              else
                raise ArgumentError, "snapshot_client must implement #get_transaction_snapshot or #get_snapshot"
              end
            end

            def record_id(record)
              if record.respond_to?(:[])
                record[:payment_intent_id] || record["payment_intent_id"] || record[:id] || record["id"]
              elsif record.respond_to?(:payment_intent_id)
                record.payment_intent_id
              elsif record.respond_to?(:id)
                record.id
              end
            end

            def determine_drift_status(local, remote)
              return :missing_remote if remote.nil?
              return :missing_local if local.nil?

              if val(local, :status) != val(remote, :status)
                return :status_drift
              end

              if val(local, :amount) != val(remote, :amount)
                return :amount_drift
              end

              if val(local, :latest_attempt_id) != val(remote, :latest_attempt_id)
                return :attempt_drift
              end

              if val(local, :captured_amount) != val(remote, :captured_amount)
                return :capture_drift
              end

              if val(local, :refunded_amount) != val(remote, :refunded_amount)
                return :refund_drift
              end

              local_curr = val(local, :currency)
              remote_curr = val(remote, :currency)
              if local_curr && remote_curr && local_curr != remote_curr
                return :amount_drift
              end

              :match
            end

            def val(record, key)
              if record.respond_to?(:[])
                record[key] || record[key.to_s]
              elsif record.respond_to?(key)
                record.public_send(key)
              end
            end
          end
        end
      end
    end
  end
end
