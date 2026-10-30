# Guía de Contribución (Contributing Guidelines)

¡Gracias por tu interés en contribuir a `Payment::SDK` (`payment-ruby-sdk`) de **AngelPixel**! Como SDK de grado financiero utilizado en el procesamiento de transacciones monetarias y conciliación contable, mantenemos estándares rigurosos de arquitectura, seguridad, documentación y calidad de código.

---

## 1. Principios de Diseño Fundamentales

Toda contribución debe respetar las directrices arquitectónicas del proyecto:

1. **Cero Dependencias Externas en Runtime:**  
   El `payment-sdk.gemspec` **no debe incluir gemas externas de runtime**. Toda la lógica de transporte, criptografía, resiliencia, serialización y validación se construye exclusivamente sobre la biblioteca estándar de Ruby (`net/http`, `openssl`, `json`, `securerandom`, `time`, `uri`).
2. **Organización Context-First (DDD):**  
   El SDK está dividido en Bounded Contexts independientes (`payments`, `refunds`, `webhooks`, `reconciliation`, `shared`). Cada Bounded Context encapsula estrictamente sus capas internas:
   - `domain/`: Entidades inmutables, Value Objects y definición de puertos conducidos (interfaces abstractas).
   - `application/`: Comandos de mutación (`BaseCommand`) y consultas de lectura (`BaseQuery`).
   - `interfaces/`: Sub-clientes invocables expuestos a la fachada principal.
3. **Protocolo Invocable Estándar (`#call`):**  
   Todos los casos de uso, comandos y consultas implementan el método unificado `#call`.
4. **Normalización a Symbols en Dominio:**  
   Las entidades de dominio normalizan todos sus estados (`@status`) a `Symbol` (`:succeeded`, `:requires_capture`, `:failed`, etc.).
5. **Idempotencia Obligatoria en Mutaciones:**  
   Todo comando que altere el estado financiero exige una clave de idempotencia validada mediante [`Shared::Domain::ValueObjects::IdempotencyKey`](../lib/payment/sdk/shared/domain/value_objects/idempotency_key.rb).
6. **Perímetro de Seguridad PCI-DSS SAQ-A y Zero-PII:**  
   Nunca se almacenan ni registran números de tarjeta crudos (PAN) ni códigos de seguridad (CVV). Toda excepción que herede de `ApiError` aplica sanitización determinista a sus datos crudos antes de salir del SDK.

---

## 2. Flujo de Trabajo con Git

Seguimos el flujo estándar basado en ramas cortas y revisión por pares:

1. **Crear una rama con prefijo semántico:**
   ```bash
   git checkout -b feature/nombre-de-la-capacidad
   # o bien:
   git checkout -b fix/descripcion-del-bug
   git checkout -b docs/actualizacion-documentacion
   ```
2. **Commits Semánticos (Conventional Commits):**  
   Usa mensajes descriptivos siguiendo el formato `tipo(alcance): descripción`:
   - `feat(...)`: Nuevas funcionalidades o endpoints del SDK.
   - `fix(...)`: Corrección de errores o deserialización.
   - `docs(...)`: Actualizaciones a documentación, README o diagramas.
   - `refactor(...)`: Mejoras de código sin alterar el comportamiento observable.
   - `style(...)`: Formato de código o alineación de StandardRB.
   - `test(...)`: Incorporación o mejora de casos de prueba.
   - `ci(...)`: Modificaciones en workflows de GitHub Actions o scripts de build.

---

## 3. Estándares de Calidad y Suite de Verificación

Antes de enviar un Pull Request, debes verificar localmente que tu código aprueba los 7 controles de calidad del proyecto:

```bash
# 1. Ejecutar las pruebas unitarias aisladas (< 0.5s, 0 dependencias externas)
bundle exec rake test

# 2. Ejecutar las pruebas de integración E2E contra el sandbox real en Docker
bundle exec rake test:integration

# 3. Analizar estilo de código con StandardRB (0 ofensas permitidas)
bundle exec standardrb

# 4. Verificar 100.00% de cobertura de documentación YARD estricta (0 warnings)
bundle exec rake yard

# 5. Auditar dependencias y CVEs conocidas
bundle exec bundle-audit check --update

# 6. Analizar vulnerabilidades de seguridad estática con Brakeman (0 warnings)
bundle exec rake security:brakeman

# 7. Validar empaquetado de la gema sin errores de gemspec
gem build payment-sdk.gemspec && rm -f payment-sdk-*.gem
```

### Reglas Específicas de Código:
- **Pruebas Espejo 1:1:** Cada nuevo archivo creado bajo `lib/payment/sdk/` debe tener su prueba unitaria espejo en `test/payment/sdk/`.
- **Documentación YARD Obligatoria:** Todos los métodos públicos y privados, constantes, clases y atributos deben documentar sus etiquetas `@param`, `@return` y `@raise`.
- **Actualización de `TREE.txt`:** Si tu cambio agrega, elimina o renombra archivos o carpetas, debes actualizar el archivo canónico [`TREE.txt`](../TREE.txt), asegurando que todas las líneas tengan su comentario `#` estrictamente alineado en la **columna 69** (`line[68] == '#'`).

---

## 4. Proceso de Pull Request

1. Haz push de tu rama a GitHub:
   ```bash
   git push origin feature/nombre-de-la-capacidad
   ```
2. Abre un **Pull Request** hacia la rama `main`.
3. Completa detalladamente la plantilla de Pull Request ([`.github/PULL_REQUEST_TEMPLATE.md`](PULL_REQUEST_TEMPLATE.md)), marcando cada ítem del checklist de verificación.
4. Asegúrate de que todos los checks de CI/CD (matriz de Ruby 3.2, 3.3, 3.4, integración con Docker y escaneos de seguridad DevSecOps) finalicen en verde.
5. El equipo de ingeniería de **AngelPixel** revisará el PR y proveerá retroalimentación constructiva.

---

## 5. Reporte de Errores y Sugerencias

- Para reportar un fallo que **no sea de seguridad**, abre un issue utilizando la plantilla correspondiente en [Issues](../../issues).
- Para reportar **vulnerabilidades de seguridad**, sigue nuestra [Política de Seguridad (`SECURITY.md`)](SECURITY.md) y envía un correo cifrado a `angel.szymczak+sec@hotmail.com`.

