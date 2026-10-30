# Roadmap 005: Gobernanza Enterprise de Repositorio en GitHub y Compliance

**Estado:** EN PROGRESO  
**Fecha de Inicio:** Octubre 2026  
**Objetivo:** Establecer la infraestructura formal de comunidad, políticas de divulgación responsable de seguridad, estándares de contribución y automatización de dependencias para operar como un SDK open-source de grado financiero y bancario.

---

### Fase 1: Política de Seguridad y Divulgación Responsable (`SECURITY.md`)
- [x] **1.1 Definición de Política de Divulgación Responsable (Responsible Disclosure)**:
  - [x] Establecer el alcance de versiones soportadas del SDK (`0.1.x`, `1.x`).
  - [x] Configurar canal de contacto cifrado/seguro (`angel.szymczak+sec@hotmail.com`).
  - [x] Definir Acuerdo de Nivel de Servicio (SLA) de respuesta: Acuse de recibo en < 24 horas y evaluación de severidad en < 72 horas.
- [x] **1.2 Delimitación de Cumplimiento PCI-DSS (SAQ-A Scope Boundary)**:
  - [x] Documentar explícitamente que el SDK opera exclusivamente bajo el modelo de tokenización (SAQ-A), sin almacenar, procesar ni transmitir números de cuenta primarios (PAN) crudos ni códigos de seguridad (CVV) en memoria persistente o disco.
  - [x] Protocolo de reporte de incidentes y remediación de CVEs con parches inmediatos (Security Advisories de GitHub).

---

### Fase 2: Guía de Contribución y Código de Conducta (`CONTRIBUTING.md` y `CODE_OF_CONDUCT.md`)
- [ ] **2.1 Código de Conducta de la Comunidad**:
  - [ ] Adoptar Contributor Covenant v2.1 en `.github/CODE_OF_CONDUCT.md` con punto de contacto en `angel.szymczak+compliance@hotmail.com`.
- [ ] **2.2 Guía Formal de Contribución (`CONTRIBUTING.md`)**:
  - [ ] Documentar la arquitectura Context-First y principios de Clean Architecture.
  - [ ] Especificar estándares obligatorios: StandardRB (0 ofensas), YARD (100.00% estricto con `--fail-on-warning`), pirámide de pruebas (unitarias en 0.3s y E2E en Docker).
  - [ ] Flujo de trabajo con ramas, commits semánticos (`feat`, `fix`, `docs`, `refactor`, `ci`) y proceso de Pull Request.

---

### Fase 3: Plantillas Estandarizadas de GitHub (`.github/PULL_REQUEST_TEMPLATE.md` e `.github/ISSUE_TEMPLATE/*`)
- [ ] **3.1 Plantilla de Pull Request (`.github/PULL_REQUEST_TEMPLATE.md`)**:
  - [ ] Checklist interactivo de verificación: Clean Architecture, tests unitarios, tests E2E, StandardRB, YARD docs y Zero-PII compliance.
- [ ] **3.2 Formularios Estructurados de Issues (GitHub Issue Forms YAML)**:
  - [ ] `.github/ISSUE_TEMPLATE/bug_report.yml`: Reporte de errores con selector de versión de Ruby, SDK y logs sanitizados.
  - [ ] `.github/ISSUE_TEMPLATE/feature_request.yml`: Propuestas de nuevas capacidades de dominio o adaptadores.
  - [ ] `.github/ISSUE_TEMPLATE/security_advisory.yml`: Redirección obligatoria hacia `SECURITY.md` para evitar divulgación pública de vulnerabilidades.
  - [ ] `.github/ISSUE_TEMPLATE/config.yml`: Configuración de soporte oficial (`angel.szymczak+support@hotmail.com`), enlaces a documentación y portal de merchants.

---

### Fase 4: Automatización de Seguridad de Cadena de Suministro (`.github/dependabot.yml`)
- [ ] **4.1 Configuración de Dependabot**:
  - [ ] Actualizaciones automáticas semanales para ecosistema Bundler (`/`).
  - [ ] Actualizaciones automáticas semanales para ecosistema GitHub Actions (`/`).
  - [ ] Agrupación de dependencias de desarrollo para evitar saturación de PRs.

---

### Fase 5: Documentación Canónica y Actualización de `TREE.txt`
- [ ] **5.1 Actualización del Árbol Canónico**:
  - [ ] Registrar todos los nuevos archivos de gobernanza en `TREE.txt` con alineación estricta en la columna 69 (`line[68] == '#'`).
- [ ] **5.2 Verificación Integral**:
  - [ ] Ejecutar `standardrb`, `rake test`, `rake yard` y verificar que el repositorio mantiene el estándar de 0 errores y 100% de documentación.