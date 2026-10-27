# frozen_string_literal: true

require "payment/sdk/infrastructure/adapters/http/client/net_http"

module Payment
  module SDK
    module Infrastructure
      module Http
        NetHttpAdapter = Payment::SDK::Infrastructure::Adapters::Http::Client::NetHttp
      end
    end
  end
end
