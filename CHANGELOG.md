# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
From the next release on, this file is maintained automatically by
[release-please](https://github.com/googleapis/release-please) from
[Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]

### Changed
- Reorganized the codebase into a Context-First layout (`payments`, `refunds`, `webhooks`, `reconciliation`, `shared`).
- Standardized Commands, Queries and Use Cases on `#call`; removed `#execute`.
- Normalized domain statuses to Symbols.
- `WebhookEvent` is now a formal class (`class WebhookEvent < Data.define(...)`) composed with `Shared::Domain::Concerns::PayloadExtractable`.

### Removed
- `examples/smoke_test.rb` (superseded by the test suite and README).

### Added
- Annotated `TREE.txt`, `TREE_TEMPLATE.txt`, technical audit and enterprise README.

## [0.1.0]

### Added
- Initial release: idempotent commands, read-only queries, webhook signature
  verification, inbox-first webhook processing and transaction reconciliation.
