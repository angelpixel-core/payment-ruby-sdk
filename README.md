# Payment Ruby SDK (`Payment::SDK`)

[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.2-red.svg)](https://www.ruby-lang.org)
[![Architecture](https://img.shields.io/badge/architecture-Clean%20%2F%20Context--First-blue.svg)](docs/ARCHITECTURE.md)
[![Tests](https://img.shields.io/badge/tests-134%20unit%20%2B%207%20e2e%20passed-brightgreen.svg)](test/)
[![YARD Docs](https://img.shields.io/badge/yard-100%25%20documented-brightgreen.svg)](https://angelpixel-core.github.io/payment-ruby-sdk/)
[![Audit Score](https://img.shields.io/badge/audit%20health-10.0%2F10%20enterprise-blueviolet.svg)](docs/audit/001-codebase_technical_audit.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

SDK idiomático en Ruby de **cero dependencias externas en runtime**, diseñado bajo los principios de **Clean Architecture**, **Hexagonal Architecture (Ports & Adapters)**, **Domain-Driven Design (DDD)**, **Bounded Contexts** y segregación **CQRS**.

---

## Índice

1. [Visión General y Principios de Diseño](#1-visión-general-y-principios-de-diseño)
2. [Arquitectura del Sistema (Context-First)](#2-arquitectura-del-sistema-context-first)
3. [Instalación](#3-instalación)
4. [Configuración Segura, Resiliencia y Observabilidad](#4-configuración-segura-resiliencia-y-observabilidad)
   - [4.1 Resiliencia HTTP y Reintentos Exponenciales](#41-resiliencia-http-y-reintentos-exponenciales)
   - [4.2 Observabilidad, Sanitización de Logs y W3C Tracing](#42-observabilidad-sanitización-de-logs-y-w3c-tracing)
5. [Guía de Integración por Bounded Context](#5-guía-de-integración-por-bounded-context)
   - [5.1 Bounded Context: Pagos (`payments`)](#51-bounded-context-pagos-payments)
   - [5.2 Bounded Context: Reembolsos (`refunds`)](#52-bounded-context-reembolsos-refunds)
   - [5.3 Bounded Context: Webhooks con Transactional Inbox (`webhooks`)](#53-bounded-context-webhooks-con-transactional-inbox-webhooks)
     - [5.3.1 Adaptador Distribuido Redis (`Inbox::Store::Redis`)](#531-adaptador-distribuido-redis-inboxstoreredis)
   - [5.4 Bounded Context: Conciliación Financiera (`reconciliation`)](#54-bounded-context-conciliación-financiera-reconciliation)
     - [5.4.1 Adaptador Persistente SQL / ActiveRecord (`Snapshot::Store::ActiveRecord`)](#541-adaptador-persistente-sql--activerecord-snapshotstoreactiverecord)
6. [Manejo de Errores y Jerarquía de Excepciones](#6-manejo-de-errores-y-jerarquía-de-excepciones)
7. [Concurrencia y Thread-Safety](#7-concurrencia-y-thread-safety)
8. [Auditoría Técnica y Estructura del Proyecto](#8-auditoría-técnica-y-estructura-del-proyecto)
9. [Guía de Desarrollo, Suite de Pruebas y CI/CD](#9-guía-de-desarrollo-suite-de-pruebas-y-cicd)

---

## 1. Visión General y Principios de Diseño

El `Payment::SDK` proporciona una capa cliente modular, predecible y mantenible para integrarse con la API v1 de la plataforma de pagos:

- **Cero Dependencias Externas en Runtime:** Construido 100% sobre la biblioteca estándar de Ruby (`net/http`, `openssl`, `json`, `securerandom`, `time`, `uri`).
- **Organización Context-First:** Cada Bounded Context (`payments`, `refunds`, `webhooks`, `reconciliation`, `shared`) encapsula físicamente su propio `domain/`, `application/` e `interfaces/`.
- **Protocolo Invocable `#call` Estándar:** Todos los comandos (`BaseCommand`), consultas (`BaseQuery`) y casos de uso implementan `#call`.
- **Normalización a Symbols:** Los estados de las entidades de dominio (`:succeeded`, `:requires_capture`, `:failed`, `:pending`, etc.) se normalizan a `Symbol`.
- **Idempotencia Mandatoria en Mutaciones:** Todo comando de mutación exige `idempotency_key` validado mediante el Value Object `Shared::Domain::ValueObjects::IdempotencyKey` e inyectado en el header `Idempotency-Key`.
- **Deduplicación de Webhooks:** Patrón *Transactional Inbox* integrado con verificación criptográfica HMAC-SHA256 en tiempo constante (`OpenSSL.fixed_length_secure_compare`) y validación de ventana temporal (`timestamp_tolerance`).

---

## 2. Arquitectura del Sistema (Context-First)

```mermaid
graph TD
    subgraph DrivingAdapters ["Driving / Primary Adapters (Interfaces)"]
        PaymentsClient["Payments::Interfaces::Client"]
        RefundsClient["Refunds::Interfaces::Client"]
        WebhooksClient["Webhooks::Interfaces::Client"]
        ReconciliationClient["Reconciliation::Interfaces::Client"]
    end

    subgraph ClientFacade ["Client Facade"]
        GlobalClient["Payment::SDK::Client"]
    end

    subgraph ApplicationLayer ["Application Layer (CQRS & Use Cases with #call)"]
        PaymentsApp["payments/application/ (commands & queries)"]
        RefundsApp["refunds/application/ (commands & queries)"]
        WebhooksApp["webhooks/application/ (use_cases/process)"]
        ReconciliationApp["reconciliation/application/ (use_cases/reconcile, queries)"]
        SharedApp["shared/application/ (BaseCommand, BaseQuery)"]
    end

    subgraph DomainLayer ["Domain Layer (Pure Core with Symbols)"]
        PaymentsDomain["payments/domain/ (Entities: PaymentIntent, PaymentAttempt, Charge)"]
        RefundsDomain["refunds/domain/ (Entities: Refund)"]
        WebhooksDomain["webhooks/domain/ (Entities: WebhookEvent, Ports: Inbox::Store, Signature::Verifier)"]
        ReconciliationDomain["reconciliation/domain/ (Ports: Snapshot::Store, Mismatch::Reporter)"]
        SharedDomain["shared/domain/ (ValueObjects: Money, Currency, IdempotencyKey, Concerns: PayloadExtractable, Ports: Http::Client)"]
    end

    subgraph DrivenAdapters ["Driven / Secondary Adapters (Infrastructure)"]
        NetHttp["Infrastructure::Adapters::Http::Client::NetHttp"]
        ErrorMapper["Infrastructure::Adapters::Http::ErrorMapper"]
        HmacVerifier["Infrastructure::Adapters::Crypto::Signature::Verifier::HmacSha256"]
        InMemoryInbox["Infrastructure::Adapters::Persistence::Inbox::Store::InMemory"]
        InMemorySnapshot["Infrastructure::Adapters::Persistence::Snapshot::Store::InMemory"]
        InMemoryMismatch["Infrastructure::Adapters::Reporting::Mismatch::Reporter::InMemory"]
        WebhookParser["Infrastructure::Adapters::Webhooks::EventParser"]
    end

    GlobalClient --> PaymentsClient
    GlobalClient --> RefundsClient
    GlobalClient --> WebhooksClient
    GlobalClient --> ReconciliationClient

    PaymentsClient --> PaymentsApp
    RefundsClient --> RefundsApp
    WebhooksClient --> WebhooksApp
    ReconciliationClient --> ReconciliationApp

    PaymentsApp --> PaymentsDomain
    PaymentsApp --> NetHttp
    RefundsApp --> RefundsDomain
    RefundsApp --> NetHttp
    WebhooksApp --> WebhooksDomain
    ReconciliationApp --> ReconciliationDomain

    DrivenAdapters -.->|Implements Ports| DomainLayer
```

---

## 3. Instalación

Agrega la gema a tu `Gemfile`:

```ruby
gem "payment-sdk", "~> 0.1.0"
```

E instala las dependencias con Bundler:

```bash
bundle install
```

---

## 4. Configuración Segura, Resiliencia y Observabilidad

Configura el SDK globalmente en el arranque de tu aplicación (por ejemplo en `config/initializers/payment_sdk.rb`):

```ruby
require "payment/sdk"
require "logger"

Payment::SDK.configure do |config|
  config.api_key        = ENV.fetch("PAYMENT_API_KEY")
  config.signing_secret = ENV.fetch("PAYMENT_SIGNING_SECRET")
  config.base_url       = ENV.fetch("PAYMENT_BASE_URL", "https://api.payment.com")
  config.timeout        = 10 # Read timeout HTTP en segundos (por defecto: 10)
  config.open_timeout   = 5  # Connection timeout en segundos (por defecto: 5)
  config.max_retries    = 2  # Reintentos ante fallos de red/5xx con backoff exponencial y jitter (por defecto: 2)
  config.logger         = Logger.new($stdout) # Logger estructurado (opcional)
end
```

### 4.1 Resiliencia HTTP y Reintentos Exponenciales

El cliente `Infrastructure::Adapters::Http::Client::NetHttp` maneja caídas transitorias de red, timeouts (`Net::OpenTimeout`, `Net::ReadTimeout`) y respuestas 5xx del servidor mediante reintentos con backoff exponencial y jitter aleatorio (`2^(attempt - 1) + rand(0.0..0.5)`).

### 4.2 Observabilidad, Sanitización de Logs y W3C Tracing

Cuando se configura `config.logger`:
- **Sanitización Automática de Secretos:** `Payment::SDK::Infrastructure::Logging::Sanitizer` intercepta y enmascara de manera determinista credenciales (`Authorization`, `api_key`, `signing_secret`, `payment_method_token`, `card_number`, `cvv`), protegiendo los logs de auditoría contra fugas de datos sensibles (PCI-DSS compliant).
- **Métricas de Latencia:** Cada solicitud registra el tiempo de respuesta preciso en `request_duration_ms` para monitoreo de SLA en sistemas APM (Datadog, OpenTelemetry, CloudWatch).
- **Trazabilidad Distribuida:** El SDK propaga automáticamente las cabeceras estándar W3C Trace Context (`traceparent`) y correlación HTTP (`X-Request-Id`). Si el llamador ya proporciona un `traceparent` o `X-Request-Id`, se respeta y propaga intacto a través de los microservicios.

### 4.3 Instanciación Aislada del Cliente

Puedes usar la configuración global o pasar una instancia específica de `Payment::SDK::Configuration` (esencial para entornos SaaS multi-tenant con credenciales independientes):

```ruby
# Usando la configuración global por defecto
client = Payment::SDK::Client.new

# Usando una configuración aislada por tenant o merchant
tenant_config = Payment::SDK::Configuration.new
tenant_config.api_key        = "sk_live_tenant_key"
tenant_config.signing_secret = "whsec_tenant_secret"
tenant_config.base_url       = "https://api.payment.com"
tenant_config.logger         = Rails.logger

tenant_client = Payment::SDK::Client.new(tenant_config)
```

---

## 5. Guía de Integración por Bounded Context

### 5.1 Bounded Context: Pagos (`payments`)

El sub-cliente `client.payments` expone los recursos `intents`, `charges` y `attempts` (además de los métodos delegados en la fachada raíz `client`):

```ruby
# 1. Crear un PaymentIntent (valida Money e IdempotencyKey antes de enviar por red)
intent = client.payments.intents.create(
  amount: 5000,                                 # Monto en centavos enteros ($50.00 USD)
  currency: "usd",                              # Código ISO 4217 de 3 letras
  customer_id: "cus_987654",
  merchant_id: "mer_123456",
  capture_method: "manual",                     # "automatic" (default) o "manual"
  idempotency_key: "checkout_order_45892_token",
  metadata: { order_id: "45892" }
)

# 2. Confirmar un PaymentIntent con un token de método de pago
confirmed = client.payments.intents.confirm(
  intent[:id],
  payment_method_token: "pm_card_visa_tok",
  idempotency_key: "confirm_order_45892_token",
  scenario: "happy_path"                        # Opcional: header X-Sandbox-Scenario
)

# 3. Capturar fondos autorizados (total o parcialmente)
captured = client.payments.intents.capture(
  intent[:id],
  amount: 5000,
  idempotency_key: "capture_order_45892_token"
)

# 4. Consultas de solo lectura (CQS Read)
fetched_intent = client.payments.intents.get(intent[:id])
lifecycle      = client.payments.intents.get_lifecycle(intent[:id])
charge         = client.payments.charges.get("ch_abc123")
attempt        = client.payments.attempts.get("pa_abc123")

# Equivalentes directos en la fachada raíz:
# client.create_payment_intent(amount: 5000, currency: "usd", idempotency_key: "...")
# client.confirm_payment_intent("pi_123", payment_method_token: "pm_...", idempotency_key: "...")
# client.capture_payment_intent("pi_123", amount: 5000, idempotency_key: "...")
# client.get_payment_intent("pi_123")
# client.get_payment_lifecycle("pi_123")
```

---

### 5.2 Bounded Context: Reembolsos (`refunds`)

Gestión de reembolsos totales o parciales sobre un cargo:

```ruby
# 1. Emitir un reembolso sobre un Charge existente
refund = client.refunds.create(
  charge_id: "ch_abc123",
  amount: 2500,                                 # Opcional (nil reembolsa el total)
  reason: "requested_by_customer",
  idempotency_key: "refund_tx_99812_token"
)

# 2. Consultar un reembolso por ID
fetched_refund = client.refunds.get("re_abc123")

# Equivalentes en la fachada raíz:
# client.create_refund(charge_id: "ch_abc123", amount: 2500, idempotency_key: "...")
# client.get_refund("re_abc123")
```

---

### 5.3 Bounded Context: Webhooks con Transactional Inbox (`webhooks`)

El caso de uso `Webhooks::Application::UseCases::Process` implementa el patrón *Transactional Inbox*:
1. Verifica si `delivery_id` ya existe en el `inbox_store` (retorna `{ status: :duplicate, entry: ... }` si el payload coincide, o lanza `ArgumentError` si hay conflicto de payload con el mismo `delivery_id`).
2. Persiste la entrada con estado `:received`.
3. Verifica la firma HMAC-SHA256 (`t=<timestamp>,v1=<hex>`) y la tolerancia temporal; si falla, actualiza el estado a `:rejected_signature` y lanza `Payment::SDK::SignatureVerificationError`.
4. Invoca `projection.apply!(inbox_entry:)` y marca la entrada como `:processed` (o `:failed` si la proyección lanza una excepción).

```ruby
class OrderWebhookProjection
  def apply!(inbox_entry:)
    event = Payment::SDK::Infrastructure::Adapters::Webhooks::EventParser.parse(
      inbox_entry[:raw_payload]
    )

    case event.event_type
    when "payment_intent.succeeded"
      # event.payment_intent_id extrae automáticamente el ID con prefijo "pi_"
      puts "Pago acreditado: #{event.payment_intent_id}"
    when "charge.refunded"
      puts "Cargo reembolsado: #{event.charge_id} (refund: #{event.refund_id})"
    end
  end
end

result = client.webhooks.process(
  payload: raw_request_body,
  signature_header: request_headers["X-Signature"],
  projection: OrderWebhookProjection.new
)

case result[:status]
when :processed
  # Evento nuevo procesado correctamente
when :duplicate
  # Entrega duplicada ignorada de forma idempotente
end
```

#### 5.3.1 Adaptador Distribuido Redis (`Inbox::Store::Redis`)

Para aplicaciones distribuidas con múltiples réplicas (Kubernetes, múltiples workers de Sidekiq/Puma), el SDK incluye `Payment::SDK::Infrastructure::Adapters::Persistence::Inbox::Store::Redis`. Diseñado mediante *duck-typing*, es compatible con gemas estándar como `redis` o `redis-client` sin obligar dependencias externas en el SDK:

```ruby
require "redis"
require "payment/sdk/infrastructure/adapters/persistence/inbox/store/redis"

redis_client = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

# TTL configurable (por defecto 7 días / 604800 segundos) para prevenir crecimiento infinito de memoria
redis_inbox = Payment::SDK::Infrastructure::Adapters::Persistence::Inbox::Store::Redis.new(
  redis: redis_client,
  ttl_seconds: 86400 * 30 # 30 días de retención
)

result = client.webhooks.process(
  payload: raw_request_body,
  signature_header: request_headers["X-Signature"],
  inbox_store: redis_inbox,
  projection: OrderWebhookProjection.new
)
```

---

### 5.4 Bounded Context: Conciliación Financiera (`reconciliation`)

Compara proyecciones locales contra el snapshot remoto (`/reports/transactions?view=snapshot`), almacena cada resultado en `snapshot_store` y reporta las discrepancias en `mismatch_reporter`.

Estados de drift detectados: `:match`, `:status_drift`, `:amount_drift`, `:attempt_drift`, `:capture_drift`, `:refund_drift`, `:missing_local` y `:missing_remote`.

```ruby
mismatch_reporter = Payment::SDK::Infrastructure::Adapters::Reporting::Mismatch::Reporter::InMemory.new

snapshots = client.reconciliation.reconcile(
  run_id: "recon_2026_10_28",
  local_records: [
    { payment_intent_id: "pi_001", amount: 1000, currency: "usd", status: "succeeded" },
    { payment_intent_id: "pi_002", amount: 5000, currency: "usd", status: "requires_capture" }
  ],
  mismatch_reporter: mismatch_reporter
)

if mismatch_reporter.reports.empty?
  puts "Conciliación limpia: #{snapshots.size} registros verificados sin drift."
else
  mismatch_reporter.reports.each do |entry|
    puts "Drift [#{entry[:status]}] en #{entry[:payment_intent_id]}"
  end
end
```

#### 5.4.1 Adaptador Persistente SQL / ActiveRecord (`Snapshot::Store::ActiveRecord`)

Para entornos empresariales donde los snapshots contables deben persistirse en bases de datos relacionales (PostgreSQL, MySQL, SQLite), el adaptador `Payment::SDK::Infrastructure::Adapters::Persistence::Snapshot::Store::ActiveRecord` desacopla la persistencia del SDK delegando en cualquier modelo ActiveRecord:

```ruby
# app/models/reconciliation_snapshot.rb
# Schema esperado: run_id (string), payment_intent_id (string), payload (jsonb/text), status (string)
class ReconciliationSnapshot < ApplicationRecord
end

active_record_store = Payment::SDK::Infrastructure::Adapters::Persistence::Snapshot::Store::ActiveRecord.new(
  model_class: ReconciliationSnapshot
)

client.reconciliation.reconcile(
  run_id: "recon_monthly_oct_2026",
  local_records: local_transactions,
  snapshot_store: active_record_store
)
```

---

## 6. Manejo de Errores y Jerarquía de Excepciones

Todas las excepciones del SDK heredan de `Payment::SDK::Error < StandardError`:

| Excepción | Superclase | Cuándo se lanza |
| :--- | :--- | :--- |
| `Payment::SDK::ConfigurationError` | `Error` | Configuración inválida del SDK. |
| `Payment::SDK::NetworkError` | `Error` | Falla de transporte o socket (tras agotar `max_retries`). |
| `Payment::SDK::TimeoutError` | `Error` | `Net::OpenTimeout` o `Net::ReadTimeout` (tras agotar `max_retries`). |
| `Payment::SDK::SignatureVerificationError` | `Error` | Firma de webhook ausente, malformada, fuera de tolerancia o inválida. |
| `Payment::SDK::ApiError` | `Error` | Base para errores HTTP devueltos por la API (`status_code`, `code`, `details`, `request_id`, `raw_body`). |
| `Payment::SDK::InvalidRequestError` | `ApiError` | HTTP 4xx o códigos `invalid_amount`, `invalid_currency`, `missing_idempotency_key`, `invalid_intent_state`, o JSON de webhook inválido. |
| `Payment::SDK::PaymentNotFoundError` | `ApiError` | HTTP 404 o códigos `payment_intent_not_found`, `charge_not_found`, `refund_not_found`. |
| `Payment::SDK::PaymentDeclinedError` | `ApiError` | Códigos `payment_declined` o `invalid_scenario`. |
| `Payment::SDK::DuplicateRequestError` | `ApiError` | HTTP 409 o código `idempotency_conflict`. |
| `Payment::SDK::UpstreamError` | `ApiError` | HTTP 5xx o códigos `internal_error`, `panic` (reintentado automáticamente hasta `max_retries`). |

```ruby
begin
  client.capture_payment_intent("pi_123", amount: 1000, idempotency_key: "cap-pi-123")
rescue Payment::SDK::PaymentDeclinedError => e
  warn "Pago rechazado (#{e.code}): #{e.message}"
rescue Payment::SDK::DuplicateRequestError => e
  warn "Conflicto de idempotencia (#{e.status_code}): #{e.request_id}"
rescue Payment::SDK::PaymentNotFoundError => e
  warn "Recurso inexistente (#{e.code})"
rescue Payment::SDK::InvalidRequestError => e
  warn "Solicitud inválida (#{e.status_code}): #{e.details}"
rescue Payment::SDK::UpstreamError, Payment::SDK::TimeoutError, Payment::SDK::NetworkError => e
  warn "Falla transitoria tras reintentos: #{e.message}"
end
```

---

## 7. Concurrencia y Thread-Safety

- **Clientes y Comandos:** `Payment::SDK::Client` duplica y valida la configuración al inicializarse (`@config = config.dup`). Cada petición HTTP construye su propia instancia de `Net::HTTP` por llamada, evitando compartir sockets mutables entre hilos concurrentes en Puma o Sidekiq.
- **Adaptadores en Memoria:** `Inbox::Store::InMemory`, `Snapshot::Store::InMemory` y `Mismatch::Reporter::InMemory` sincronizan todas las lecturas y escrituras mediante `Mutex#synchronize` y retornan copias defensivas (`dup`) para evitar mutaciones externas.
- **Adaptadores Distribuidos:** `Inbox::Store::Redis` delega la atomicidad en comandos nativos de Redis (`SET NX`, `GET`) y soporta pools de conexión concurrentes; `Snapshot::Store::ActiveRecord` aprovecha el connection pool nativo de base de datos por hilo.

---

## 8. Auditoría Técnica y Estructura del Proyecto

- 📄 **[Auditoría Técnica y Evaluación de Arquitectura (docs/audit/001-codebase_technical_audit.md)](docs/audit/001-codebase_technical_audit.md)**
- 🏛️ **[Especificación de Arquitectura (docs/ARCHITECTURE.md)](docs/ARCHITECTURE.md)**
- 🌲 **[Estructura Canónica Anotada (TREE.txt)](TREE.txt)**
- 📐 **[Plantilla Arquetípica de Bounded Context (TREE_TEMPLATE.txt)](TREE_TEMPLATE.txt)**
- 📋 **[Changelog (CHANGELOG.md)](CHANGELOG.md)**
- 🗺️ **[Roadmap 003: CI/CD, Observabilidad y Persistencia (docs/roadmap/003-enterprise_cicd_observability_and_persistence.md)](docs/roadmap/003-enterprise_cicd_observability_and_persistence.md)**

---

## 9. Guía de Desarrollo, Suite de Pruebas y CI/CD

El proyecto cuenta con una pirámide de pruebas enterprise dividida en dos suites independientes:

### 9.1 Suite Unitaria Aislada (Rápida y Pura)

No requiere Docker, bases de datos ni conexión a internet. Se ejecuta en ~0.01s:

```bash
# Ejecutar las 134 pruebas unitarias con advertencias habilitadas
bundle exec rake test
```

### 9.2 Suite de Integración E2E (Testcontainers & Sandbox Real)

Orquesta programáticamente el contenedor de la API real en Go (`angelszymczak/payment-sandbox:latest`), asigna puertos dinámicos efímeros, verifica el healthcheck y valida el ciclo de vida completo de pagos, capturas, reembolsos, idempotencia, concurrencia multi-hilo y conciliación contable:

```bash
# Requiere Docker en ejecución local
bundle exec rake test:integration
```

### 9.3 Calidad, Linting, Seguridad y Documentación

```bash
# Analizar estilo con StandardRB (0 ofensas permitidas)
bundle exec standardrb

# Auditoría de dependencias y vulnerabilidades conocidas
bundle exec bundle-audit check --update

# Verificar 100% de cobertura de documentación YARD estricta
bundle exec rake yard

# Validar empaquetado de la gema sin warnings
gem build payment-sdk.gemspec
```

### 9.4 Pipeline de Integración Continua (CI/CD)

En `.github/workflows/ci.yml`:
1. **Matriz Multi-Ruby (`verify`):** Ejecuta StandardRB, bundler-audit, suite unitaria (`rake test`), cobertura YARD y compilación de gema en Ruby **3.2**, **3.3** y **3.4**.
2. **Suite E2E con Caché de Docker (`integration`):** Corre `rake test:integration` descargando y cacheando la imagen de `angelszymczak/payment-sandbox:latest` con `actions/cache@v4` para acelerar los pipelines y evitar descargas redundantes.

### Convenciones para Contribuciones
1. **Context-First:** Todo nuevo componente debe ubicarse dentro de su Bounded Context (`lib/payment/sdk/<context>/`).
2. **Protocolo `#call`:** Comandos, consultas y casos de uso implementan `#call`.
3. **Symbols en Dominio:** Las entidades normalizan su `@status` a `Symbol`.
4. **Pruebas Espejo 1:1:** Todo archivo en `lib/` cuenta con su prueba unitaria correspondiente en `test/`.
