# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/reconciliation/ports/snapshot/store"

class DomainReconciliationPortsSnapshotStoreTest < Minitest::Test
  class UnimplementedStore
    include Payment::SDK::Domain::Reconciliation::Ports::Snapshot::Store
  end

  def setup
    @store = UnimplementedStore.new
  end

  def test_save_raises_not_implemented
    assert_raises(NotImplementedError) do
      @store.save({ id: "snap_1" })
    end
  end

  def test_find_raises_not_implemented
    assert_raises(NotImplementedError) do
      @store.find("snap_1")
    end
  end

  def test_all_raises_not_implemented
    assert_raises(NotImplementedError) do
      @store.all
    end
  end
end
