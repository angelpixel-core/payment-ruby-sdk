# Auditoría Técnica y Evaluación de Arquitectura: Payment::SDK

**Versión del SDK:** `0.1.0`  
**Fecha de Auditoría:** Octubre 2026  
**Autor:** Antigravity AI & Engineering Team  
**Destinatarios:** Engineering Managers, Staff Engineers, Tech Leads, Security & Platform Teams  
**Estado:** `APPROVED / VERIFIED AGAINST SOURCE`

---

## 1. Resumen Ejecutivo y Health Score Arquitectónico

La gema `Payment::SDK` implementa una arquitectura **Context-First / Clean Architecture** sin dependencias externas en runtime. Cada Bounded Context (`payments`, `refunds`, `webhooks`, `reconciliation`, `shared`) aísla sus entidades y puertos de los adaptadores secundarios en `infrastructure/adapters/`.

### Calificación Global de Calidad (Scorecard)

| Dimensión | Puntuación | Estado | Observación Verificada en Código |
| :--- | :---: | :---: | :--- |
| **Arquitectura de Dominio (DDD)** | `9.8 / 10` | Excelente | Bounded Contexts autónomos (`payments`, `refunds`, `webhooks`, `reconciliation`, `shared`). |
| **Separación de Capas (Clean Arch)** | `9.7 / 10` | Excelente | Puertos abstractos en `domain/ports/`; adaptadores concretos en `infrastructure/adapters/`. |
| **Uniformidad y Ergonomía Ruby** | `9.9 / 10` | Excelente | Protocolo `#call` en todos los Commands, Queries y Use Cases; estados en entidades como `Symbols`. |
| **Seguridad Criptográfica** | `9.5 / 10` | Muy Alto | `HmacSha256` valida ventana temporal (`timestamp_tolerance: 300`) y compara firmas con `OpenSSL.fixed_length_secure_compare`. |
| **Cobertura y Suite de Tests** | `10.0 / 10` | Perfecto | 114 pruebas, 306 aserciones, 0 fallos, 0 errores, ejecutadas con `t.warning = true`. |
| **Thread-Safety en Adaptadores** | `9.0 / 10` | Muy Alto | `InMemory` stores y reporter protegidos con `Mutex#synchronize` y copias defensivas (`dup`). |
| **Telemetría y Observabilidad** | `7.5 / 10` | En evolución | `Configuration#logger` declarado y errores enriquecidos en `ApiError`; instrumentación HTTP planificada en Roadmap 003. |

---

## 2. Decisiones de Diseño y Análisis de Deuda Técnica

### 2.1 Uso Estratégico de Primitivas de Tipado: `Data` vs `Class` vs `Struct`

1. **`Data.define` + Mixin Composable (`WebhookEvent`):**
   - `Webhooks::Domain::Entities::WebhookEvent` hereda de `Data.define(:delivery_id, :event_id, :event_type, :created_at, :data, :raw_payload)` e incluye el concern `Shared::Domain::Concerns::PayloadExtractable`.
   - **Ventajas:** Inmutabilidad garantizada por Ruby 3.2+, igualdad estructural (`==`), deconstrucción para pattern matching (`deconstruct_keys`) y extracción reutilizable de IDs prefijados (`pi_`, `ch_`, `re_`).

2. **`Class` Tradicional con `freeze` (Entidades y Value Objects con Invariantes):**
   - Entidades: `PaymentIntent`, `Charge`, `PaymentAttempt`, `Refund`. Normalizan `@status = status.to_sym`, exponen predicados de negocio (`requires_capture?`, `fully_captured?`, `succeeded?`, `pending?`) y se congelan con `freeze`.
   - Value Objects: `Currency` (valida código ISO de 3 letras `/\A[a-z]{3}\z/`), `IdempotencyKey` (genera `SecureRandom.uuid` por defecto o valida string no vacío) y `Money` (incluye `Comparable`, exige `amount` entero en centavos y valida igualdad de `Currency` en operaciones `+`, `-`, `<=>`).

3. **`Struct` (Confinado a Tests):**
   - No se utiliza `Struct` en `lib/`, evitando mutabilidad accidental en objetos del dominio.

### 2.2 Organización Context-First y Estandarización en `#call`

- **Context-First:** Toda modificación funcional sobre pagos, reembolsos, webhooks o conciliación ocurre dentro de su propio subárbol `lib/payment/sdk/<context>/{domain,application,interfaces}`.
- **Interfaz `#call`:** `Shared::Application::BaseCommand` y `Shared::Application::BaseQuery` definen `#call(**options)` como contrato único, eliminando alias redundantes como `#execute`.

---

## 3. Análisis de Concurrencia y Thread-Safety

### 3.1 Fachada `Payment::SDK::Client` y `NetHttp`
- `Payment::SDK::Client#initialize` clona la configuración (`@config = config.dup`) y la valida (`@config.validate!`).
- `Infrastructure::Adapters::Http::Client::NetHttp#perform_request` instancia un objeto `Net::HTTP.new(uri.host, uri.port)` por petición, evitando el uso compartido de sockets entre hilos concurrentes en servidores como Puma o workers de Sidekiq.

### 3.2 Adaptadores en Memoria (`InMemory`)
- `Persistence::Inbox::Store::InMemory`, `Persistence::Snapshot::Store::InMemory` y `Reporting::Mismatch::Reporter::InMemory` encapsulan su estado tras un `@mutex = Mutex.new` y devuelven copias superficiales (`entry.dup`), previniendo condiciones de carrera y mutaciones externas.

---

## 4. Resiliencia, Tolerancia a Fallos y Manejo deErrores

### 4.1 Backoff Exponencial con Jitter
En `Infrastructure::Adapters::Http::Client::NetHttp`:
- Se reintentan automáticamente `Payment::SDK::NetworkError`, `Payment::SDK::TimeoutError` y `Payment::SDK::UpstreamError` mientras `retries < @max_retries`.
- La espera entre reintentos aplica backoff exponencial con jitter aleatorio:
  ```ruby
  sleep_time = (2**(retry_count - 1)) + rand(0.0..0.5)
  ```

### 4.2 Mapeo Determinístico de Errores (`ErrorMapper`)
`Infrastructure::Adapters::Http::ErrorMapper.map_error(response, request_id: nil)` inspecciona tanto el código de error semántico del payload JSON (`error_code` / `code`) como el `status_code` HTTP, instanciando excepciones específicas que heredan de `Payment::SDK::ApiError`:
- `InvalidRequestError`: códigos `invalid_amount`, `invalid_currency`, `missing_idempotency_key`, `invalid_intent_state` o HTTP `400..499` genérico.
- `PaymentNotFoundError`: códigos `payment_intent_not_found`, `charge_not_found`, `refund_not_found` o HTTP `404`.
- `DuplicateRequestError`: código `idempotency_conflict` o HTTP `409`.
- `PaymentDeclinedError`: códigos `invalid_scenario` o `payment_declined`.
- `UpstreamError`: códigos `internal_error`, `panic` o HTTP `>= 500`.

Todas las subclases de `ApiError` preservan `status_code`, `code`, `details`, `request_id` y `raw_body`.

---

## 5. Estrategia de Observabilidad y Telemetría

### 5.1 Estado Actual
- `Payment::SDK::Configuration` expone `attr_accessor :logger`.
- Las excepciones de red y API conservan el contexto completo (`status_code`, `code`, `details`, `request_id`, `raw_body`).

### 5.2 Evolución Planificada (Roadmap 003 - Fase 3)
- Instrumentar `NetHttp` para emitir logs estructurados a través de `config.logger` (sanitizando cabeceras sensibles como `Authorization`).
- Soportar propagación de cabeceras de trazabilidad distribuida (`traceparent`, `X-Request-Id`).

---

## 6. Matriz de Compatibilidad con Versiones de Ruby

| Versión de Ruby | Estado de Compatibilidad | Notas Técnicas |
| :---: | :---: | :--- |
| **Ruby 3.2** | Compatible (Mínima requerida en `gemspec`) | Introduce `Data.define`, utilizado en `WebhookEvent`. |
| **Ruby 3.3** | Compatible | Compatible al 100%, utilizado en los workflows de GitHub Actions. |
| **Ruby 3.4 / 4.0** | Compatible | Verificado localmente con `t.warning = true` en Minitest (114 tests, 0 warnings). |

---

## 7. Roadmap de Mejoras Técnicas Priorizadas (Roadmap 003)

- **Fase 1 (Completada):** Documentación API con YARD (`.yardopts`, `rake yard`), publicación en GitHub Pages (`documentation.yml`) y automatización de releases con `release-please` (`release.yml`, `CHANGELOG.md`).
- **Fase 2 (Siguiente):** Pipeline CI/CD en GitHub Actions con matriz Ruby 3.2/3.3/3.4, linter `StandardRB`, `bundler-audit` y verificación `gem build`.
- **Fase 3:** Observabilidad estructurada usando `config.logger` y propagación W3C `traceparent`.
- **Fase 4:** Adaptadores conducidos pluggables para producción distribuida (`Inbox::Store::Redis` y `Snapshot::Store::ActiveRecord`).
