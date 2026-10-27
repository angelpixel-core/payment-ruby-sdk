# frozen_string_literal: true

require "payment/sdk/application/reconciliation/use_cases/reconcile"

module Payment
  module SDK
    module Application
      module UseCases
        ReconcileTransactions = Payment::SDK::Application::Reconciliation::UseCases::Reconcile
      end
    end
  end
end
