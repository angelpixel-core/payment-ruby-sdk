# frozen_string_literal: true

require "payment/sdk/reconciliation/application/use_cases/reconcile"
require "payment/sdk/reconciliation/application/queries/reports/get"
require "payment/sdk/reconciliation/application/queries/snapshots/get"
require "payment/sdk/infrastructure/adapters/persistence/snapshot/store/in_memory"
require "payment/sdk/infrastructure/adapters/reporting/mismatch/reporter/in_memory"

module Payment
  module SDK
    module Reconciliation
      module Interfaces
        # Entry point of the reconciliation bounded context.
        class Client
          # @return [#request] HTTP port used by the queries
          attr_reader :http_client

          # @param http_client [#request] implementation of the HTTP client port
          # @param snapshot_store [Object, nil] snapshot store port (in-memory by default)
          # @param mismatch_reporter [Object, nil] mismatch reporter port (in-memory by default)
          def initialize(http_client:, snapshot_store: nil, mismatch_reporter: nil)
            @http_client = http_client
            @snapshot_store = snapshot_store
            @mismatch_reporter = mismatch_reporter
          end

          # @param local_records [Array<Hash>] local projections to compare
          # @param run_id [String] identifier of the reconciliation run
          # @param snapshot_store [Object, nil] overrides the client's store
          # @param mismatch_reporter [Object, nil] overrides the client's reporter
          # @return [Object] reconciliation result
          def reconcile(local_records:, run_id:, snapshot_store: nil, mismatch_reporter: nil)
            store = snapshot_store || @snapshot_store || default_snapshot_store
            reporter = mismatch_reporter || @mismatch_reporter || default_mismatch_reporter

            use_case = Application::UseCases::Reconcile.new(
              snapshot_client: self,
              snapshot_store: store,
              mismatch_reporter: reporter
            )
            use_case.call(local_records: local_records, run_id: run_id)
          end

          # @param start_date [String, nil]
          # @param end_date [String, nil]
          # @return [Object] transaction report
          def get_report(start_date: nil, end_date: nil)
            query = Application::Queries::Reports::Get.new(@http_client)
            query.call(start_date: start_date, end_date: end_date)
          end

          # @param start_date [String, nil]
          # @param end_date [String, nil]
          # @return [Object] deterministic transaction snapshot
          def get_snapshot(start_date: nil, end_date: nil)
            query = Application::Queries::Snapshots::Get.new(@http_client)
            query.call(start_date: start_date, end_date: end_date)
          end

          alias_method :get_transaction_report, :get_report
          alias_method :get_transaction_snapshot, :get_snapshot

          private

          def default_snapshot_store
            @default_snapshot_store ||= Infrastructure::Adapters::Persistence::Snapshot::Store::InMemory.new
          end

          def default_mismatch_reporter
            @default_mismatch_reporter ||= Infrastructure::Adapters::Reporting::Mismatch::Reporter::InMemory.new
          end
        end
      end
    end
  end
end
