# frozen_string_literal: true

require "test_helper"
require "payment/sdk/shared/domain/ports/http/client"

class SharedDomainPortsHttpClientTest < Minitest::Test
  class UnimplementedClient
    include Payment::SDK::Shared::Domain::Ports::Http::Client
  end

  def test_request_raises_not_implemented
    client = UnimplementedClient.new
    assert_raises(NotImplementedError) do
      client.request(method: :get, path: "/test")
    end
  end
end
