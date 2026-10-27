# frozen_string_literal: true

require "test_helper"
require "payment/sdk/domain/shared/ports/http/client"

class SharedHttpClientPortTest < Minitest::Test
  class DummyClient
    include Payment::SDK::Domain::Shared::Ports::Http::Client
  end

  def test_raises_not_implemented_by_default
    client = DummyClient.new
    assert_raises(NotImplementedError) do
      client.request(method: :get, path: "/test")
    end
  end
end
