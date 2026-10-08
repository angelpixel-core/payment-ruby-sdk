# frozen_string_literal: true

module Payment
  module SDK
    module Application
      module UseCases
        class ReconcileTransactions
          def initialize(snapshot_client:, snapshot_store:, mismatch_reporter:)
            @snapshot_client = snapshot_client
            @snapshot_store = snapshot_store
            @mismatch_reporter = mismatch_reporter
          end

          def call(local_records:, run_id:)
            # Make sure we don't mutate input arrays
            local_records = local_records.map(&:dup)
            
            remote_records = @snapshot_client.get_transaction_snapshot
            
            local_map = local_records.to_h { |r| [r[:payment_intent_id], r] }
            remote_map = remote_records.to_h { |r| [r[:payment_intent_id], r] }

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

          def determine_drift_status(local, remote)
            return :missing_remote if remote.nil?
            return :missing_local if local.nil?

            if local[:status] != remote[:status]
              return :status_drift
            end

            if local[:amount] != remote[:amount]
              return :amount_drift
            end

            if local[:latest_attempt_id] != remote[:latest_attempt_id]
              return :attempt_drift
            end

            if local[:captured_amount] != remote[:captured_amount]
              return :capture_drift
            end

            if local[:refunded_amount] != remote[:refunded_amount]
              return :refund_drift
            end

            # Optionally we can check :currency, etc.
            if local[:currency] && remote[:currency] && local[:currency] != remote[:currency]
              return :amount_drift # or currency_drift, reusing amount_drift for monetary mismatches
            end

            :match
          end
        end
      end
    end
  end
end
