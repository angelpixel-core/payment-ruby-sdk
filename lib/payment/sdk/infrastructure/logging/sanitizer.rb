# frozen_string_literal: true

require "uri"
require "json"

module Payment
  module SDK
    module Infrastructure
      # Infrastructure layer encompassing technical logging, adapters, and transport.
      module Logging
        # Utility for redacting sensitive values such as credentials, secrets,
        # tokens, and payment data from logs, headers, and URLs.
        class Sanitizer
          # Replacement text for redacted values.
          FILTERED = "[FILTERED]"

          # Header names that must have their values redacted.
          SENSITIVE_HEADERS = %w[
            authorization
            x-api-key
            api-key
            signature
            x-signature
            client-secret
            secret
          ].freeze

          # Query parameter and payload keys that must have their values redacted.
          SENSITIVE_KEYS = %w[
            api_key
            secret
            signing_secret
            token
            access_token
            password
            cvv
            cvc
            card_number
            payment_method_token
          ].freeze

          # Redacts sensitive header values.
          #
          # @param headers [Hash, nil] headers hash
          # @return [Hash] copy with sensitive headers redacted
          def self.sanitize_headers(headers)
            return {} unless headers.is_a?(Hash)

            headers.each_with_object({}) do |(key, value), acc|
              k_str = key.to_s
              acc[k_str] = if SENSITIVE_HEADERS.include?(k_str.downcase)
                FILTERED
              else
                value
              end
            end
          end

          # Redacts sensitive query parameters from a URL or URI object.
          #
          # @param url [String, URI, nil] URL to sanitize
          # @return [String, nil] sanitized URL string
          def self.sanitize_url(url)
            return nil if url.nil?

            uri = url.is_a?(URI) ? url.dup : URI.parse(url.to_s)
            return uri.to_s unless uri.query

            params = URI.decode_www_form(uri.query)
            sanitized_params = params.map do |k, v|
              k_down = k.to_s.downcase
              if SENSITIVE_KEYS.any? { |key| k_down == key || k_down.include?(key) }
                [k, FILTERED]
              else
                [k, v]
              end
            end
            uri.query = URI.encode_www_form(sanitized_params)
            uri.to_s
          rescue URI::InvalidURIError
            url.to_s
          end

          # Redacts sensitive keys from a raw string or JSON payload.
          #
          # @param raw_body [String, nil] raw response or request body
          # @return [String, nil] sanitized string
          def self.sanitize_raw_body(raw_body)
            return nil if raw_body.nil?
            return raw_body unless raw_body.is_a?(String)

            parsed = JSON.parse(raw_body)
            JSON.generate(sanitize_payload(parsed))
          rescue JSON::ParserError
            masked = raw_body.dup
            SENSITIVE_KEYS.each do |key|
              masked.gsub!(/(["']?#{Regexp.escape(key)}["']?\s*[:=]\s*["']?)([^"',\s]+)(["']?)/i, "\\1#{FILTERED}\\3")
            end
            masked
          end

          # Recursively redacts sensitive keys from a Hash or Array payload.
          #
          # @param payload [Object] payload to sanitize
          # @return [Object] sanitized payload
          def self.sanitize_payload(payload)
            case payload
            when Hash
              payload.each_with_object({}) do |(k, v), acc|
                k_down = k.to_s.downcase
                acc[k] = if SENSITIVE_KEYS.any? { |key| k_down == key || k_down.include?(key) }
                  FILTERED
                else
                  sanitize_payload(v)
                end
              end
            when Array
              payload.map { |item| sanitize_payload(item) }
            else
              payload
            end
          end
        end
      end
    end
  end
end
