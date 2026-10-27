# Roadmap: Normalización Arquitectónica y Migración Vertical por Bounded Contexts

Este roadmap establece la reestructuración del SDK aplicando **Clean Architecture**, **Arquitectura Hexagonal (Ports & Adapters / Drivers & Driven)**, **Domain-Driven Design (DDD)** y **CQRS**, garantizando principios **SOLID** (en particular **SRP** e **ISP**).

---

## 1. Mapeo de Capas Arquitectónicas (Hexagonal & Clean Architecture)

| Concepto Arquitectónico | Capa en el SDK | Rol y Responsabilidad | Ejemplos Concretos con Namespaces (`::`) |
| :--- | :--- | :--- | :--- |
| **Driving / Primary Adapters** (Entrada) | `interfaces/` (y Facade raíz) | Conducen la aplicación hacia adentro. Puntos de entrada para el consumidor o desarrollador. | `Payment::SDK::Client`<br>`Payment::SDK::Interfaces::Payments::Client`<br>`Payment::SDK::Interfaces::Refunds::Client`<br>`Payment::SDK::Interfaces::Webhooks::Client`<br>`Payment::SDK::Interfaces::Reconciliation::Client`<br>`Payment::SDK::Interfaces::CLI::Console` |
| **Use Cases / CQRS** | `application/` | Orquestan la lógica de aplicación sin dependencias de transporte ni persistencia. | `Payment::SDK::Application::Payments::Commands::Intents::Create`<br>`Payment::SDK::Application::Payments::Queries::Intents::Get`<br>`Payment::SDK::Application::Refunds::Commands::Create`<br>`Payment::SDK::Application::Webhooks::UseCases::Process`<br>`Payment::SDK::Application::Reconciliation::UseCases::Reconcile` |
| **Core Domain & Contracts** | `domain/` | Lógica pura de negocio, reglas invariantes y contratos abstractos (**Ports**). | **Entities**:<br>`Payment::SDK::Domain::Payments::Entities::PaymentIntent`<br>`Payment::SDK::Domain::Refunds::Entities::Refund`<br>**Value Objects**:<br>`Payment::SDK::Domain::Shared::ValueObjects::Money`<br>`Payment::SDK::Domain::Shared::ValueObjects::Currency`<br>**Ports (Contratos sin sufijo redundante)**:<br>`Payment::SDK::Domain::Shared::Ports::Http::Client`<br>`Payment::SDK::Domain::Webhooks::Ports::Inbox::Store`<br>`Payment::SDK::Domain::Webhooks::Ports::Signature::Verifier`<br>`Payment::SDK::Domain::Reconciliation::Ports::Snapshot::Store`<br>`Payment::SDK::Domain::Reconciliation::Ports::Mismatch::Reporter` |
| **Driven / Secondary Adapters** (Salida) | `infrastructure/adapters/` | Adaptadores conducidos por el dominio/aplicación para hablar con el exterior (Especialización por implementación al final). | `Payment::SDK::Infrastructure::Adapters::Http::Client::NetHttp`<br>`Payment::SDK::Infrastructure::Adapters::Crypto::Signature::Verifier::HmacSha256`<br>`Payment::SDK::Infrastructure::Adapters::Persistence::Inbox::Store::InMemory`<br>`Payment::SDK::Infrastructure::Adapters::Persistence::Snapshot::Store::InMemory`<br>`Payment::SDK::Infrastructure::Adapters::Reporting::Mismatch::Reporter::InMemory`<br>`Payment::SDK::Infrastructure::Adapters::Webhooks::EventParser` |

> **Convenciones de Nomenclatura y Namespaces**:
> - En Ruby y DDD idiomático se utilizan carpetas y módulos en plural (`interfaces/`, `ports/`, `adapters/`, `entities/`, `commands/`, `queries/`).
> - **Puertos (`domain/.../ports/`)**: Definen el rol/capacidad sin sufijo redundante `Port` (ej: `Ports::Inbox::Store`, `Ports::Signature::Verifier`).
> - **Adaptadores (`infrastructure/adapters/`)**: Siguen la jerarquía `Categoría::Concepto::Rol::TecnologíaConcreta` (ej: `Persistence::Inbox::Store::InMemory`, `Crypto::Signature::Verifier::HmacSha256`).
> - Los **Puertos (Ports)** residen siempre dentro de la capa `domain/`.
> - Los **Adaptadores Secundarios (Adapters)** residen en `infrastructure/adapters/`.

---

## 2. Fases de Ejecución Vertical (Checklist de Tareas)

### Fase 0: Cimientos Compartidos (Shared Domain & Application Base)
- [x] **0.1 Value Objects** en `lib/payment/sdk/domain/shared/value_objects/`:
  - [x] `Payment::SDK::Domain::Shared::ValueObjects::Money` (`money.rb`)
  - [x] `Payment::SDK::Domain::Shared::ValueObjects::Currency` (`currency.rb`)
  - [x] `Payment::SDK::Domain::Shared::ValueObjects::IdempotencyKey` (`idempotency_key.rb`)
- [x] **0.2 Puertos Compartidos** en `lib/payment/sdk/domain/shared/ports/http/`:
  - [x] `Payment::SDK::Domain::Shared::Ports::Http::Client` (`client.rb`)
- [x] **0.3 Clases Base de Aplicación** en `lib/payment/sdk/application/shared/`:
  - [x] `Payment::SDK::Application::Shared::BaseCommand` (`base_command.rb`)
  - [x] `Payment::SDK::Application::Shared::BaseQuery` (`base_query.rb`)
- [x] **0.4 Pruebas Unitarias Granulares**:
  - [x] `test/payment/sdk/domain/shared/value_objects/money_test.rb`
  - [x] `test/payment/sdk/domain/shared/value_objects/currency_test.rb`
  - [x] `test/payment/sdk/domain/shared/value_objects/idempotency_key_test.rb`
  - [x] `test/payment/sdk/domain/shared/ports/http/client_test.rb`
  - [x] `test/payment/sdk/application/shared/base_command_test.rb`
  - [x] `test/payment/sdk/application/shared/base_query_test.rb`
- [x] **0.5 Validación**:
  - [x] Ejecutar `bundle exec rake test` (100% verde).

---

### Fase 1: Bounded Context Vertical — `payments`
- [x] **1.1 Dominio (`domain/payments/`)**:
  - [x] `Payment::SDK::Domain::Payments::Entities::PaymentIntent` (`entities/payment_intent.rb`)
  - [x] `Payment::SDK::Domain::Payments::Entities::PaymentAttempt` (`entities/payment_attempt.rb`)
  - [x] `Payment::SDK::Domain::Payments::Entities::Charge` (`entities/charge.rb`)
- [x] **1.2 Aplicación (`application/payments/`)**:
  - [x] Comandos en `application/payments/commands/intents/`:
    - [x] `Payment::SDK::Application::Payments::Commands::Intents::Create` (`create.rb`)
    - [x] `Payment::SDK::Application::Payments::Commands::Intents::Confirm` (`confirm.rb`)
    - [x] `Payment::SDK::Application::Payments::Commands::Intents::Capture` (`capture.rb`)
  - [x] Consultas en `application/payments/queries/`:
    - [x] `Payment::SDK::Application::Payments::Queries::Intents::Get` (`intents/get.rb`)
    - [x] `Payment::SDK::Application::Payments::Queries::Charges::Get` (`charges/get.rb`)
    - [x] `Payment::SDK::Application::Payments::Queries::Attempts::Get` (`attempts/get.rb`)
    - [x] `Payment::SDK::Application::Payments::Queries::Lifecycles::Get` (`lifecycles/get.rb`)
- [x] **1.3 Interfaz / Sub-cliente (`interfaces/payments/`)**:
  - [x] `Payment::SDK::Interfaces::Payments::Client` (`lib/payment/sdk/interfaces/payments/client.rb`) exponiendo `.intents.create`, `.intents.get`, etc.
- [x] **1.4 Adaptadores Secundarios de Transporte HTTP (`infrastructure/adapters/http/`)**:
  - [x] `Payment::SDK::Infrastructure::Adapters::Http::Client::NetHttp` (`client/net_http.rb`)
  - [x] `Payment::SDK::Infrastructure::Adapters::Http::ErrorMapper` (`error_mapper.rb`)
- [x] **1.5 Integración en Client Facade**:
  - [x] Conectar `client.payments` hacia `Payment::SDK::Interfaces::Payments::Client` y delegar métodos directos (`create_payment_intent`, etc.).
- [x] **1.6 Pruebas Unitarias Granulares 1:1**:
  - [x] `test/payment/sdk/domain/payments/entities/payment_intent_test.rb`
  - [x] `test/payment/sdk/domain/payments/entities/charge_test.rb`
  - [x] `test/payment/sdk/domain/payments/entities/payment_attempt_test.rb`
  - [x] `test/payment/sdk/application/payments/commands/intents/create_test.rb`
  - [x] `test/payment/sdk/application/payments/commands/intents/confirm_test.rb`
  - [x] `test/payment/sdk/application/payments/commands/intents/capture_test.rb`
  - [x] `test/payment/sdk/application/payments/queries/intents/get_test.rb`
  - [x] `test/payment/sdk/application/payments/queries/charges/get_test.rb`
  - [x] `test/payment/sdk/application/payments/queries/attempts/get_test.rb`
  - [x] `test/payment/sdk/application/payments/queries/lifecycles/get_test.rb`
  - [x] `test/payment/sdk/interfaces/payments/client_test.rb`
  - [x] `test/payment/sdk/infrastructure/adapters/http/client/net_http_test.rb`
- [x] **1.7 Validación**:
  - [x] Ejecutar `bundle exec rake test` (100% verde).

---

### Fase 2: Bounded Context Vertical — `refunds`
- [ ] **2.1 Dominio (`domain/refunds/`)**:
  - [ ] `Payment::SDK::Domain::Refunds::Entities::Refund` (`entities/refund.rb`)
- [ ] **2.2 Aplicación (`application/refunds/`)**:
  - [ ] `Payment::SDK::Application::Refunds::Commands::Create` (`commands/create.rb`)
  - [ ] `Payment::SDK::Application::Refunds::Queries::Get` (`queries/get.rb`)
- [ ] **2.3 Interfaz / Sub-cliente (`interfaces/refunds/`)**:
  - [ ] `Payment::SDK::Interfaces::Refunds::Client` (`lib/payment/sdk/interfaces/refunds/client.rb`)
- [ ] **2.4 Integración en Client Facade**:
  - [ ] Conectar `client.refunds` y delegar `create_refund`, `get_refund`.
- [ ] **2.5 Pruebas Unitarias Granulares 1:1**:
  - [ ] `test/payment/sdk/domain/refunds/entities/refund_test.rb`
  - [ ] `test/payment/sdk/application/refunds/commands/create_test.rb`
  - [ ] `test/payment/sdk/application/refunds/queries/get_test.rb`
  - [ ] `test/payment/sdk/interfaces/refunds/client_test.rb`
- [ ] **2.6 Validación**:
  - [ ] Ejecutar `bundle exec rake test` (100% verde).

---

### Fase 3: Bounded Context Vertical — `webhooks`
- [ ] **3.1 Dominio (`domain/webhooks/`)**:
  - [ ] `Payment::SDK::Domain::Webhooks::Entities::WebhookEvent` (`entities/webhook_event.rb`)
  - [ ] Puertos en `domain/webhooks/ports/`:
    - [ ] `Payment::SDK::Domain::Webhooks::Ports::Inbox::Store` (`inbox/store.rb`)
    - [ ] `Payment::SDK::Domain::Webhooks::Ports::Signature::Verifier` (`signature/verifier.rb`)
- [ ] **3.2 Adaptadores Secundarios (`infrastructure/adapters/`)**:
  - [ ] `Payment::SDK::Infrastructure::Adapters::Crypto::Signature::Verifier::HmacSha256` (`crypto/signature/verifier/hmac_sha256.rb`)
  - [ ] `Payment::SDK::Infrastructure::Adapters::Persistence::Inbox::Store::InMemory` (`persistence/inbox/store/in_memory.rb`)
  - [ ] `Payment::SDK::Infrastructure::Adapters::Webhooks::EventParser` (`webhooks/event_parser.rb`)
- [ ] **3.3 Aplicación (`application/webhooks/`)**:
  - [ ] `Payment::SDK::Application::Webhooks::UseCases::Process` (`use_cases/process.rb`)
- [ ] **3.4 Interfaz / Sub-cliente (`interfaces/webhooks/`)**:
  - [ ] `Payment::SDK::Interfaces::Webhooks::Client` (`lib/payment/sdk/interfaces/webhooks/client.rb`)
- [ ] **3.5 Integración en Client Facade**:
  - [ ] Conectar `client.webhooks` y delegar `process_webhook`.
- [ ] **3.6 Pruebas Unitarias Granulares 1:1**:
  - [ ] `test/payment/sdk/domain/webhooks/entities/webhook_event_test.rb`
  - [ ] `test/payment/sdk/domain/webhooks/ports/inbox/store_test.rb`
  - [ ] `test/payment/sdk/domain/webhooks/ports/signature/verifier_test.rb`
  - [ ] `test/payment/sdk/infrastructure/adapters/crypto/signature/verifier/hmac_sha256_test.rb`
  - [ ] `test/payment/sdk/infrastructure/adapters/persistence/inbox/store/in_memory_test.rb`
  - [ ] `test/payment/sdk/application/webhooks/use_cases/process_test.rb`
  - [ ] `test/payment/sdk/interfaces/webhooks/client_test.rb`
- [ ] **3.7 Validación**:
  - [ ] Ejecutar `bundle exec rake test` (100% verde).

---

### Fase 4: Bounded Context Vertical — `reconciliation`
- [ ] **4.1 Dominio (`domain/reconciliation/`)**:
  - [ ] Puertos en `domain/reconciliation/ports/`:
    - [ ] `Payment::SDK::Domain::Reconciliation::Ports::Snapshot::Store` (`snapshot/store.rb`)
    - [ ] `Payment::SDK::Domain::Reconciliation::Ports::Mismatch::Reporter` (`mismatch/reporter.rb`)
- [ ] **4.2 Adaptadores Secundarios (`infrastructure/adapters/`)**:
  - [ ] `Payment::SDK::Infrastructure::Adapters::Persistence::Snapshot::Store::InMemory` (`persistence/snapshot/store/in_memory.rb`)
  - [ ] `Payment::SDK::Infrastructure::Adapters::Reporting::Mismatch::Reporter::InMemory` (`reporting/mismatch/reporter/in_memory.rb`)
- [ ] **4.3 Aplicación (`application/reconciliation/`)**:
  - [ ] `Payment::SDK::Application::Reconciliation::UseCases::Reconcile` (`use_cases/reconcile.rb`)
  - [ ] Consultas en `application/reconciliation/queries/`:
    - [ ] `Payment::SDK::Application::Reconciliation::Queries::Reports::Get` (`reports/get.rb`)
    - [ ] `Payment::SDK::Application::Reconciliation::Queries::Snapshots::Get` (`snapshots/get.rb`)
- [ ] **4.4 Interfaz / Sub-cliente (`interfaces/reconciliation/`)**:
  - [ ] `Payment::SDK::Interfaces::Reconciliation::Client` (`lib/payment/sdk/interfaces/reconciliation/client.rb`)
- [ ] **4.5 Integración en Client Facade**:
  - [ ] Conectar `client.reconciliation` y delegar `reconcile`, `get_transaction_report`, `get_transaction_snapshot`.
- [ ] **4.6 Pruebas Unitarias Granulares 1:1**:
  - [ ] `test/payment/sdk/domain/reconciliation/ports/snapshot/store_test.rb`
  - [ ] `test/payment/sdk/domain/reconciliation/ports/mismatch/reporter_test.rb`
  - [ ] `test/payment/sdk/infrastructure/adapters/persistence/snapshot/store/in_memory_test.rb`
  - [ ] `test/payment/sdk/infrastructure/adapters/reporting/mismatch/reporter/in_memory_test.rb`
  - [ ] `test/payment/sdk/application/reconciliation/use_cases/reconcile_test.rb`
  - [ ] `test/payment/sdk/application/reconciliation/queries/reports/get_test.rb`
  - [ ] `test/payment/sdk/application/reconciliation/queries/snapshots/get_test.rb`
  - [ ] `test/payment/sdk/interfaces/reconciliation/client_test.rb`
- [ ] **4.7 Validación**:
  - [ ] Ejecutar `bundle exec rake test` (100% verde).

---

### Fase 5: Limpieza, Consolidación y Verificación de Release
- [ ] **5.1** Eliminar archivos obsoletos y carpetas residuales vacías.
- [ ] **5.2** Actualizar documentación de arquitectura en `docs/ARCHITECTURE.md`.
- [ ] **5.3** Actualizar el árbol canónico en `TREE.txt`.
- [ ] **5.4** Ejecutar `examples/smoke_test.rb` y verificar ejecución sin advertencias ni errores.
- [ ] **5.5** Ejecutar suite completa con `bundle exec rake test` (todas las aserciones pasando al 100%).
