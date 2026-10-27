# frozen_string_literal: true

require "test_helper"
require "payment/sdk/application/shared/base_query"

class SharedBaseQueryTest < Minitest::Test
  def test_base_query_initialization
    client = Object.new
    query = Payment::SDK::Application::Shared::BaseQuery.new(client)
    assert_equal client, query.http_client
  end
end
