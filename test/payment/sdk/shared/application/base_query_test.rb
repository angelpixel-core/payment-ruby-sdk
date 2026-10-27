# frozen_string_literal: true

require "test_helper"
require "payment/sdk/shared/application/base_query"

class SharedApplicationBaseQueryTest < Minitest::Test
  class DummyQuery < Payment::SDK::Shared::Application::BaseQuery
    def call(id:)
      { queried: id }
    end
  end

  class UnimplementedQuery < Payment::SDK::Shared::Application::BaseQuery
  end

  def setup
    @http_client = Object.new
    @query = DummyQuery.new(@http_client)
  end

  def test_subclass_must_implement_call
    unimplemented = UnimplementedQuery.new(@http_client)
    assert_raises(NotImplementedError) do
      unimplemented.call
    end
  end

  def test_call_executes_query
    result = @query.call(id: "123")
    assert_equal({ queried: "123" }, result)
  end

  def test_execute_alias_delegates_to_call
    result = @query.execute(id: "123")
    assert_equal({ queried: "123" }, result)
  end
end
