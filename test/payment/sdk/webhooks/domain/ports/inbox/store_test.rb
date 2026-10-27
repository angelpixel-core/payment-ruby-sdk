# frozen_string_literal: true

require "test_helper"
require "payment/sdk/webhooks/domain/ports/inbox/store"

class WebhooksDomainPortsInboxStoreTest < Minitest::Test
  class UnimplementedStore
    include Payment::SDK::Webhooks::Domain::Ports::Inbox::Store
  end

  def setup
    @store = UnimplementedStore.new
  end

  def test_save_raises_not_implemented
    assert_raises(NotImplementedError) do
      @store.save({ delivery_id: "del_1" })
    end
  end

  def test_find_by_delivery_id_raises_not_implemented
    assert_raises(NotImplementedError) do
      @store.find_by_delivery_id("del_1")
    end
  end

  def test_update_status_raises_not_implemented
    assert_raises(NotImplementedError) do
      @store.update_status(delivery_id: "del_1", status: :processed)
    end
  end
end
