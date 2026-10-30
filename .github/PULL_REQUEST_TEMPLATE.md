## Descripción del Cambio

<!-- Explica de forma clara y concisa el propósito del Pull Request y el problema que resuelve. -->

### Tipo de Cambio
- [ ] `feat`: Nueva funcionalidad o capacidad en el SDK
- [ ] `fix`: Corrección de un error o deserialización
- [ ] `docs`: Modificación o adición de documentación técnica
- [ ] `refactor`: Refactorización interna sin alterar el comportamiento observable
- [ ] `perf`: Optimización de rendimiento o consumo de memoria
- [ ] `test`: Incorporación o mejora de pruebas unitarias o de integración
- [ ] `ci`: Modificaciones en workflows de CI/CD o pipelines DevSecOps

### Bounded Context Afectado
- [ ] `payments`: Pagos, cargos, intentos y ciclo de vida de cobro
- [ ] `refunds`: Reembolsos parciales o totales
- [ ] `webhooks`: Ingestión, verificación de firmas y Transactional Inbox
- [ ] `reconciliation`: Conciliación contable y discrepancias
- [ ] `shared`: Kernel compartido (Money, Currency, IdempotencyKey)
- [ ] `infrastructure`: Adaptadores HTTP, resiliencia, persistencia o logging
- [ ] `ci / governance`: Gobernanza, workflows o dependencias

---

## Lista de Verificación de Calidad (Checklist Obligatorio)

Marca cada ítem tras verificarlo localmente antes de solicitar revisión:

- [ ] **Arquitectura Context-First:** El código respeta la separación estricta de capas (`domain/`, `application/`, `interfaces/`, `infrastructure/`).
- [ ] **Protocolo Invocable `#call`:** Todos los comandos (`BaseCommand`), consultas (`BaseQuery`) y casos de uso implementan `#call`.
- [ ] **Symbols en Dominio:** Las entidades normalizan todos sus estados (`@status`) a `Symbol`.
- [ ] **Idempotencia Estricta:** Las mutaciones validan su `idempotency_key` mediante `Shared::Domain::ValueObjects::IdempotencyKey`.
- [ ] **Zero-PII Compliance:** No se registran ni persisten datos sensibles de tarjeta (PAN, CVV) ni claves secretas en logs o excepciones.
- [ ] **Pruebas Unitarias:** `bundle exec rake test` ejecutado con éxito (0 fallos, 0 errores).
- [ ] **Pruebas de Integración E2E:** `bundle exec rake test:integration` verificado contra el Sandbox real en Docker (si aplica).
- [ ] **Linter Ruby:** `bundle exec standardrb` verificado con **0 ofensas**.
- [ ] **Documentación YARD:** `bundle exec rake yard` verificado al **100.00% documentado** (0 componentes sin documentar, 0 advertencias con `--fail-on-warning`).
- [ ] **Auditoría de Vulnerabilidades:** `bundle exec bundle-audit check` sin vulnerabilidades en dependencias.
- [ ] **Seguridad Estática SAST:** `bundle exec rake security:brakeman` con **0 advertencias** de seguridad.
- [ ] **Compilación de Gema:** `gem build payment-sdk.gemspec` compila limpiamente sin advertencias.
- [ ] **Árbol Canónico `TREE.txt`:** Si se agregaron, eliminaron o renombraron archivos, [`TREE.txt`](../TREE.txt) ha sido actualizado manteniendo los comentarios `#` estrictamente alineados en la **columna 69** (`line[68] == '#'`).

---

## ¿Introduce Cambios que Rompen Compatibilidad (Breaking Changes)?
- [ ] No
- [ ] Sí (describir la ruta de migración requerida para los merchants):
