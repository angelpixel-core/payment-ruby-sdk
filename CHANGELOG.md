# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
From the next release on, this file is maintained automatically by
[release-please](https://github.com/googleapis/release-please) from
[Conventional Commits](https://www.conventionalcommits.org/).

## [0.2.0](https://github.com/angelpixel-core/payment-ruby-sdk/compare/payment-sdk-v0.1.0...payment-sdk/v0.2.0) (2026-10-30)


### Features

* **application:** implement CQRS mutation commands with idempotency validation ([38e12ee](https://github.com/angelpixel-core/payment-ruby-sdk/commit/38e12eea176fecb0b1af867a9839f66a78b2bf44))
* **application:** implement CQRS read queries ([0afdfaf](https://github.com/angelpixel-core/payment-ruby-sdk/commit/0afdfafcedb5860565f0a582113cdbac701a63bd))
* **application:** implement read-only reconciliation engine and drift detection ([05ecaa1](https://github.com/angelpixel-core/payment-ruby-sdk/commit/05ecaa1f4a047a29ff91754085c17087a49db167))
* **application:** implement resilient inbox pattern and ProcessWebhook use case ([00a47c3](https://github.com/angelpixel-core/payment-ruby-sdk/commit/00a47c370fcb0ba5f69f1faf17c4faaff4df16eb))
* **architecture:** reorganize codebase to context-first layout ([d48f527](https://github.com/angelpixel-core/payment-ruby-sdk/commit/d48f527896b86a976740b6ffbffd2819c2edc16d))
* **core:** normalize bounded contexts, enterprise resilience, devsecops, and governance ([047dfdd](https://github.com/angelpixel-core/payment-ruby-sdk/commit/047dfddbc4e56a696d716c9e2432b674c94e4ee0))
* **docs:** add YARD documentation, GitHub Pages workflow and release-please automation ([ca02405](https://github.com/angelpixel-core/payment-ruby-sdk/commit/ca02405da871444ce2622f7f7c2ecfe29ad13a0e))
* **domain:** implement value objects, entities, and ports ([6f07c03](https://github.com/angelpixel-core/payment-ruby-sdk/commit/6f07c03fb9c8d77650363b44ee986f1848be69ab))
* **governance:** implement PR template, structured issue forms, dependabot, and TREE.txt (Roadmap 005 Fases 3-5) ([0dc7488](https://github.com/angelpixel-core/payment-ruby-sdk/commit/0dc748872e14ac829dd444894e9d42737b39c58f))
* **infra:** implement native Net::HTTP adapter and error mapper ([c2b83f9](https://github.com/angelpixel-core/payment-ruby-sdk/commit/c2b83f9c3f41b584ffbe058634c8e7c939069497))
* **observability:** add structured logging, secret sanitization, and W3C trace context propagation ([b6211e8](https://github.com/angelpixel-core/payment-ruby-sdk/commit/b6211e873fd8b3960597aabfd0ba64a716101607))
* **payments:** implement Phase 1 - vertical bounded context for payments (domain, application, interfaces, adapters, and tests) ([3c6682e](https://github.com/angelpixel-core/payment-ruby-sdk/commit/3c6682e74c34fe9e1819406f8c2655b2c75c3a3c))
* **persistence:** implement Inbox::Store::Redis and Snapshot::Store::ActiveRecord distributed adapters ([d5d0df3](https://github.com/angelpixel-core/payment-ruby-sdk/commit/d5d0df37300c940889a56886b32d33bf8c29257e))
* **reconciliation:** implement Phase 4 - vertical bounded context for reconciliation ([86a8c31](https://github.com/angelpixel-core/payment-ruby-sdk/commit/86a8c31e0e33b9b53080bf671fb2f0e477c6c4a6))
* **refunds:** implement Phase 2 - vertical bounded context for refunds (domain, application, interfaces, and tests) ([ca3d3fe](https://github.com/angelpixel-core/payment-ruby-sdk/commit/ca3d3fe53ec97fedf045a819cfdc13a7b89c63d2))
* **release:** implement Client facade, smoke tests, packaging, and clean up tmp directory ([ac351f0](https://github.com/angelpixel-core/payment-ruby-sdk/commit/ac351f04f1da0cc79054354ccf9ac30a0af80e9c))
* **resilience:** implement rate limiting 429 Retry-After, native circuit breaker, in-memory TTL, and zero-pii sanitization (Fase 2) ([8221392](https://github.com/angelpixel-core/payment-ruby-sdk/commit/82213929314f1ebebd29b6d28c8810f1ea8fa919))
* **sdk:** setup gem foundation, configuration, and test suite (Milestone 01) ([8ae7bb4](https://github.com/angelpixel-core/payment-ruby-sdk/commit/8ae7bb4fe2c6f0c20626d87ef23b2133a2571bea))
* **security:** implement webhook event parser and HMAC-SHA256 signature verifier ([a756069](https://github.com/angelpixel-core/payment-ruby-sdk/commit/a756069f04f876d05e362767cacb317cb3ac320f))
* **shared:** implement Phase 0 - shared domain value objects, ports, and base application classes ([93f68ad](https://github.com/angelpixel-core/payment-ruby-sdk/commit/93f68ad0b4d7a3d8dbaa7c7a68b973f58a989ddc))
* **webhooks:** implement Phase 3 - vertical bounded context for webhooks (Data event, ports, specialized adapters, client, and tests) ([dcce231](https://github.com/angelpixel-core/payment-ruby-sdk/commit/dcce231753e31597d78ca5336861e43f4d34bfd2))

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
