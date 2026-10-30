# frozen_string_literal: true

require "test_helper"
require "testcontainers"
require "net/http"
require "uri"

module Payment
  # Manages the lifecycle of the `angelszymczak/payment-sandbox` Docker container
  # for live integration tests.
  module IntegrationTestSandbox
    IMAGE = "angelszymczak/payment-sandbox:latest"
    CONTAINER_PORT = 8080

    class << self
      # Returns the base URL of the running sandbox API, starting the container if necessary.
      #
      # @return [String] base URL without trailing slash
      def base_url
        @base_url ||= start!
      end

      # Starts the sandbox container (unless `PAYMENT_API_URL` environment variable is set).
      #
      # @return [String] base URL
      def start!
        if ENV["PAYMENT_API_URL"] && !ENV["PAYMENT_API_URL"].empty?
          @base_url = ENV["PAYMENT_API_URL"].sub(%r{/$}, "")
          return @base_url
        end

        return @base_url if @base_url

        @container = Testcontainers::DockerContainer.new(IMAGE).with_exposed_port(CONTAINER_PORT)
        @container.start

        host = @container.host
        port = @container.mapped_port(CONTAINER_PORT)
        @base_url = "http://#{host}:#{port}"

        wait_for_health!
        @base_url
      end

      # Stops and removes the active container.
      #
      # @return [void]
      def stop!
        return unless @container

        @container.stop
        @container.delete
        @container = nil
        @base_url = nil
      end

      private

      def wait_for_health!(max_retries: 30, sleep_interval: 0.2)
        uri = URI("#{@base_url}/health")
        max_retries.times do
          begin
            response = Net::HTTP.get_response(uri)
            return if response.code == "200"
          rescue
            # Container still initializing
          end
          sleep sleep_interval
        end

        raise "Sandbox container at #{@base_url} failed to become healthy within timeout"
      end
    end
  end

  # Base class for live end-to-end integration test cases against the Payment Sandbox.
  class IntegrationTest < Minitest::Test
    # @return [Payment::SDK::Client]
    attr_reader :client

    def setup
      super
      @base_url = IntegrationTestSandbox.base_url
      @client = Payment::SDK::Client.new(
        Payment::SDK::Configuration.new.tap do |c|
          c.base_url = @base_url
          c.api_key = "test_key_live"
          c.signing_secret = "whsec_test_secret"
        end
      )
    end
  end
end

Minitest.after_run do
  Payment::IntegrationTestSandbox.stop!
end
