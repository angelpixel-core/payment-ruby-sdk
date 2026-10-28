# Roadmap 003: CI/CD, Observabilidad Enterprise y Persistencia Distribuida

Este roadmap formaliza el siguiente gran salto evolutivo de la gema `Payment::SDK` tras la sesión de arquitectura interactiva (`/grill-me`). Su propósito es llevar el SDK a un nivel de madurez operativa y de ingeniería de grado enterprise, incorporando automatización de releases, documentación YARD, pipeline de integración continua robusto, observabilidad estructurada y adaptadores de persistencia para entornos de producción concurrentes y distribuidos.

---

## 1. Decisiones Clave Acordadas (`/grill-me`)

| Dimensión | Decisión Adoptada | Justificación Técnica |
| :--- | :--- | :--- |
| **Secuencia de Fases** | **1. YARD & Release → 2. CI/CD StandardRB → 3. Observabilidad → 4. Adaptadores** | Definido expresamente por el usuario para establecer primero las bases de release y calidad antes de extender capacidades técnicas. |
| **Documentación API** | **YARD con `.yardopts`, tarea `rake yard` y GitHub Pages** | Generación de documentación estandarizada de tipos y parámetros, desplegada automáticamente en la rama `gh-pages` ante pushes a `main`. |
| **Automatización de Release** | **Híbrido Enterprise: `release-please` (Conventional Commits)** | Automatiza la creación de Release PRs, cálculo de versión semántica en `version.rb`, generación de `CHANGELOG.md` y publicación de releases al mergear. |
| **Calidad de Código y CI** | **StandardRB + Matriz Multi-Ruby (3.2, 3.3, 3.4)** | Reglas estrictas sin debate de configuración (*zero-configuration*), combinado con `bundle-audit` para CVEs y verificación de empaquetado `gem build`. |
| **Observabilidad y Telemetría** | **`config.logger` estructurado + Trazas W3C agnósticas** | Inyección de logger (`Logger`, `Rails.logger`), logueo estructurado de peticiones HTTP (latencia, status, sanitización de credenciales) y propagación de cabeceras de trazabilidad (`traceparent`, `X-Request-Id`) sin añadir gemas pesadas en runtime. |
| **Persistencia Distribuida** | **Adaptadores conducidos pluggables (Redis y SQL/ActiveRecord)** | Implementaciones de `Inbox::Store` y `Snapshot::Store` por *duck-typing* que reciben la conexión del host (ej. `redis_client`), preservando la política de cero dependencias obligatorias en el `gemspec`. |

---

## 2. Diagrama Arquitectónico Objetivo (Fase Enterprise)

```mermaid
graph TD
    subgraph HostApplication ["Host Application (Rails / Puma / Sidekiq)"]
        HostLogger["Host Logger (Rails.logger)"]
        HostRedis["Redis Connection Pool"]
        HostDB["ActiveRecord / DB Connection"]
    end

    subgraph SDKCore ["Payment::SDK Core (Stateless & Thread-Safe)"]
        Config["Configuration (logger, trace_headers, timeouts)"]
        Client["Payment::SDK::Client"]
        
        subgraph Contexts ["Bounded Contexts (#call & Symbols)"]
            Payments["payments/"]
            Refunds["refunds/"]
            Webhooks["webhooks/ (Transactional Inbox)"]
            Recon["reconciliation/ (Financial Drift Engine)"]
        end
    end

    subgraph InfrastructureLayer ["Infrastructure Driven Adapters"]
        NetHttp["Adapters::Http::Client::NetHttp (Retries + Structured Logging)"]
        RedisInbox["Adapters::Persistence::Inbox::Store::Redis (Distributed TTL Inbox)"]
        SqlSnapshot["Adapters::Persistence::Snapshot::Store::ActiveRecord (Audited DB Snapshots)"]
        MemStores["Adapters::Persistence::*::InMemory (Test / Dev Doubles)"]
    end

    subgraph AutomationPipeline ["CI/CD & Release Pipeline"]
        Actions["GitHub Actions (Ruby 3.2, 3.3, 3.4)"]
        StandardLint["StandardRB (Static Analysis)"]
        SecurityAudit["Bundle Audit (CVE Checks)"]
        YARDBuild["YARD Documentation -> GitHub Pages"]
        ReleasePlease["Release Please (Changelog & SemVer Bump)"]
    end

    HostApplication -->|Injects config & connections| Client
    Client --> Contexts
    Contexts -.-> NetHttp
    Webhooks -.-> RedisInbox
    Webhooks -.-> MemStores
    Recon -.-> SqlSnapshot
    Recon -.-> MemStores
    NetHttp -.-> HostLogger
    RedisInbox -.-> HostRedis
    SqlSnapshot -.-> HostDB
```

---

## 3. Fases de Ejecución Detalladas (Checklist de Tareas)

### Fase 1: Documentación API con YARD y Release Automation
- [x] **1.1 Configuración de YARD**:
  - [x] Agregar `gem "yard"` en el grupo de desarrollo en `Gemfile`.
  - [x] Crear archivo `.yardopts` configurando títulos, formato markdown y exclusión de tests.
  - [x] Agregar tarea `rake yard` en `Rakefile`.
  - [x] Documentar con tags YARD (`@param`, `@return`, `@raise`) las clases públicas fundamentales (`Client`, entidades y sub-clientes) alcanzando **100.00% de cobertura YARD** con `--fail-on-warning`.
- [x] **1.2 Pipeline de GitHub Pages**:
  - [x] Crear workflow `.github/workflows/documentation.yml` para compilar y desplegar YARD docs en GitHub Pages en push a `main`.
- [x] **1.3 Automatización de Release con `release-please`**:
  - [x] Crear configuración `.release-please-config.json` y `.release-please-manifest.json`.
  - [x] Crear workflow `.github/workflows/release.yml` integrando `googleapis/release-please-action`.
  - [x] Inicializar `CHANGELOG.md` con el estándar *Keep a Changelog* documentando las versiones 0.1.0 y cambios actuales.

---

### Fase 2: Pipeline de CI/CD Completo (StandardRB y Multi-Ruby)
- [ ] **2.1 Configuración de StandardRB**:
  - [ ] Agregar `gem "standard"` en `Gemfile` (grupo `:development, :test`).
  - [ ] Ejecutar `bundle exec standardrb` y formatear el código si fuera necesario (`--fix`).
  - [ ] Agregar tarea de linter a la ejecución por defecto de Rake.
- [ ] **2.2 Auditoría de Seguridad y Empaquetado**:
  - [ ] Agregar `gem "bundler-audit"` para detección de CVEs.
  - [ ] Crear tarea Rake `rake audit` y `rake build` para validar el empaquetado del `.gem`.
- [ ] **2.3 Workflow de CI en GitHub Actions**:
  - [ ] Crear `.github/workflows/ci.yml` con matriz de prueba:
    - Versiones de Ruby: `3.2`, `3.3`, `3.4`.
    - Pasos: Checkout, Setup Ruby, Bundle Install, `standardrb`, `bundle-audit`, `rake test`, y `gem build`.

---

### Fase 3: Observabilidad y Telemetría Enterprise
- [ ] **3.1 Logger Contextual Inyectable**:
  - [ ] Extender `Configuration` con `attr_accessor :logger, :log_level`.
  - [ ] Implementar decorador/helper de logging interno seguro que sanitice tokens y headers sensibles (Authorization, Signing Secret).
  - [ ] Instrumentar el cliente HTTP (`NetHttp`) para registrar eventos estructurados en formato clave-valor o JSON (método, URL sanitizada, código de respuesta, duración en milisegundos).
- [ ] **3.2 Propagación de Trazabilidad Distribuida (W3C Trace Context)**:
  - [ ] Permitir inyección de `traceparent` o `request_id` en las opciones de comandos y llamadas HTTP.
  - [ ] Propagar cabeceras `traceparent` y `X-Request-Id` hacia las peticiones de red salientes.
- [ ] **3.3 Tests Espejo y Verificación**:
  - [ ] Tests unitarios para el comportamiento del logger y la sanitización de secretos.
  - [ ] Tests para la propagación de cabeceras de trazabilidad.

---

### Fase 4: Adaptadores Conducidos de Persistencia Distribuida
- [ ] **4.1 Adaptador `Inbox::Store::Redis`**:
  - [ ] Crear `lib/payment/sdk/infrastructure/adapters/persistence/inbox/store/redis.rb` implementando el puerto `Webhooks::Domain::Ports::Inbox::Store`.
  - [ ] Soportar operaciones atómicas con TTL configurable para evitar saturación de memoria.
  - [ ] Diseñado mediante *duck-typing* para aceptar cualquier cliente compatible con Redis (ej. `redis`, `redis-client`).
- [ ] **4.2 Adaptador `Snapshot::Store::ActiveRecord` / `SQL`**:
  - [ ] Crear `lib/payment/sdk/infrastructure/adapters/persistence/snapshot/store/active_record.rb` implementando el puerto `Reconciliation::Domain::Ports::Snapshot::Store`.
  - [ ] Mapeo transparente entre entidades de dominio y registros de base de datos relacional.
- [ ] **4.3 Tests Espejo y Mocks**:
  - [ ] Pruebas unitarias completas con dobles de prueba sin exigir Redis ni DB local corriendo para pasar la suite.

---

### Fase 5: Documentación, Actualización del Árbol y Release
- [ ] **5.1 Actualización de `TREE.txt`**:
  - [ ] Regenerar `TREE.txt` con las nuevas rutas de adaptadores, workflows y concerns alineados a la columna 68.
- [ ] **5.2 Actualización de `README.md` y `docs/audit/`**:
  - [ ] Documentar en `README.md` la configuración del logger, el uso de Redis para webhooks y los workflows de CI/CD.
  - [ ] Marcar en la auditoría técnica (`001-codebase_technical_audit.md`) la resolución de las tareas P1 y P2.
- [ ] **5.3 Validación Integral**:
  - [ ] Ejecutar `bundle exec rake test` (100% verde).
  - [ ] Ejecutar `bundle exec standardrb` (0 ofensas).
  - [ ] Ejecutar `gem build payment-sdk.gemspec` (empaquetado exitoso).
- [ ] **5.4 Commit y Tag Semántico de Release**.
