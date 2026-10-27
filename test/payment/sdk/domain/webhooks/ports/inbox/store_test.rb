# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/webhooks/ports/inbox/store"

class DomainWebhooksPortsInboxStoreTest < Minitest::Test
  class DummyStore
    include Payment::SDK::Domain::Webhooks::Ports::Inbox::Store
  end

  def test_raises_not_implemented
    store = DummyStore.new
    assert_raises(NotImplementedError) { store.find_by_delivery_id("d1") }
    assert_raises(NotImplementedError) { store.persist({}) }
    assert_raises(NotImplementedError) { store.update("d1", {}) }
  end
end
