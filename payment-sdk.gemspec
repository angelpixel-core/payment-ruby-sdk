# frozen_string_literal: true

require_relative "lib/payment/sdk/version"

Gem::Specification.new do |spec|
  spec.name = "payment-sdk"
  spec.version = Payment::SDK::VERSION
  spec.authors = ["Angel Szymczak"]
  spec.email = ["contact@angelpixel.io"]

  spec.summary = "Ruby SDK for the Payment Platform v1 API."
  spec.description = <<~DESC.tr("\n", " ").strip
    Zero-dependency Ruby client for the Payment Platform v1 contract:
    idempotent commands, read-only queries, webhook signature verification,
    inbox-first webhook processing, and transaction reconciliation.
  DESC
  spec.homepage = "https://github.com/angelpixel-core/payment-ruby-sdk"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  # Explicit file list: does not depend on git, so `tmp/`, `docs/` and tests
  # never end up inside the packaged gem.
  spec.files = Dir["lib/**/*.rb", "README.md", "CHANGELOG.md", "LICENSE*"]
  spec.require_paths = ["lib"]

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # No runtime dependencies by design: only Ruby stdlib
  # (net/http, openssl, json, securerandom, time).
  # Development dependencies live in the Gemfile.
end
