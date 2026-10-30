# Roadmap 006: Protocolos Financieros Avanzados de la Industria de Pagos

**Estado:** PLANIFICADO  
**Fecha de Inicio:** Pendiente de finalización de Roadmap 005  
**Objetivo:** Implementar los protocolos requeridos por pasarelas y adquirentes del mundo real (divisas multi-escala ISO 4217, rotación de claves en webhooks sin tiempo de inactividad, orquestación de autenticación 3DS2/SCA y tokens de billeteras digitales) con el fin de certificar la calidad enterprise del producto.

---

### Fase 1: Matemáticas Financieras y Divisas ISO 4217 Avanzadas
- [ ] **1.1 Soporte de Monedas Cero-Decimales (Zero-Decimal Currencies)**:
  - [ ] Adaptar `Currency` y `Money` para reconocer divisas sin subdivisión fraccionaria (ej. `JPY`, `KRW`, `CLP`, `VND`, `PYG`).
  - [ ] Validar que montos en divisas cero-decimales se expresen directamente como enteros sin multiplicar por 100.
- [ ] **1.2 Soporte de Monedas de Tres Decimales (Three-Decimal Currencies)**:
  - [ ] Adaptar `Currency` y `Money` para reconocer divisas con tres decimales (ej. `BHD`, `KWD`, `OMR`, `JOD`, `TND`).
  - [ ] Implementar conversión precisa por factor 1000 evitando errores de redondeo de punto flotante en punto decimal.
- [ ] **1.3 Normalización y Prevención de Desbordamiento**:
  - [ ] Pruebas unitarias de conversión cruzada, sumas y serialización en centavos normalizados.

---

### Fase 2: Rotación de Secretos Criptográficos en Webhooks (Zero-Downtime Signature Rotation)
- [ ] **2.1 Verificación Multi-Secreto Simultáneo**:
  - [ ] Extender `Signature::Verifier::HmacSha256` para aceptar un secreto único o una colección de secretos activos (`secrets: [secret_current, secret_previous]`).
  - [ ] Permitir la transición fluida durante la ventana de rotación de credenciales bancarias sin rechazar eventos legítimos ni cortar el servicio.
- [ ] **2.2 Esquemas de Versión de Firma (`t=...,v1=...,v2=...`)**:
  - [ ] Parsear firmas con múltiples esquemas de versión y validar compatibilidad hacia adelante.
- [ ] **2.3 Pruebas de Integración de Rotación Cero-Caída**:
  - [ ] Validar eventos firmados con clave anterior, clave nueva y combinaciones inválidas en tiempo constante.

---

### Fase 3: Orquestación de Autenticación 3D Secure 2 (3DS2) y SCA (Strong Customer Authentication)
- [ ] **3.1 Modelado del Estado `:requires_action` en `PaymentIntent`**:
  - [ ] Formalizar la transición hacia `:requires_action` cuando el emisor bancario exige autenticación PSD2 / SCA.
- [ ] **3.2 DTOs y Value Objects para `next_action`**:
  - [ ] Crear estructura para `redirect_to_url` (URL de challenge 3DS2, retorno de URL post-autenticación).
  - [ ] Crear estructura para `use_sdk_challenge` (Fingerprint 3DS2 y parámetros EMVCo).
- [ ] **3.3 Sub-cliente de Reanudación de Pagos**:
  - [ ] Exponer método `client.payments.intents.confirm` con soporte de resultado 3DS post-challenge.
  - [ ] Pruebas unitarias completas de la máquina de estados 3DS2.

---

### Fase 4: Billeteras Digitales y Network Tokens (Apple Pay / Google Pay / Click to Pay)
- [ ] **4.1 Abstracción de Tokens de Billeteras Digitales**:
  - [ ] DTOs tipados para datos de pago encriptados PKCS#7 (Apple Pay) y tokens JSON criptográficos (Google Pay).
- [ ] **4.2 Mapeo Transparente hacia `payment_method_token`**:
  - [ ] Normalización hacia el agregado `PaymentIntent` sin exponer datos sensibles fuera del perímetro seguro.
- [ ] **4.3 Pruebas de Integración y Validación de Esquemas**:
  - [ ] Simulación de pagos con Network Tokens y verificación de campos obligatorios.

---

### Fase 5: Documentación de Cumplimiento Normativo (PCI-DSS SAQ-A & EMVCo Guidelines)
- [ ] **5.1 Guía de Arquitectura de Seguridad y Cumplimiento**:
  - [ ] Crear `docs/compliance/001-pci_dss_and_emvco_guidelines.md` documentando la matriz de responsabilidad compartida entre el merchant, el SDK y la pasarela.
- [ ] **5.2 Actualización del Árbol Canónico `TREE.txt` y 100% YARD**:
  - [ ] Documentar todas las nuevas clases, tipos y métodos con YARD estricto.
  - [ ] Alinear `TREE.txt` en la columna 69 y ejecutar suite completa (`rake test`, `rake test:integration`, `standardrb`, `bundle-audit`, `brakeman`).

