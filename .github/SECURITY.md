# Política de Seguridad y Divulgación Responsable (Security Policy)

En **AngelSolutions** nos tomamos con la máxima seriedad la seguridad de nuestros sistemas, la integridad de los datos financieros y la protección de los usuarios. Si has identificado una vulnerabilidad de seguridad en el `Payment::SDK` (`payment-ruby-sdk`), te agradecemos tu colaboración para reportarla de forma responsable.

---

## 1. Versiones Soportadas

Actualmente proporcionamos parches de seguridad y mantenimiento para las siguientes versiones del SDK:

| Versión | Soportada | Estado de Soporte |
| :--- | :---: | :--- |
| `0.1.x` | ✅ | Versión activa de arquitectura normalizada y endurecida. |
| `< 0.1.0` | ❌ | Versiones de prototipo obsoletas; se recomienda actualizar de inmediato. |

---

## 2. Reporte de Vulnerabilidades (Responsible Disclosure)

**Por favor, NO abras un issue público en GitHub para reportar vulnerabilidades de seguridad.** La divulgación pública prematura expone a los merchants y a sus usuarios finales antes de que un parche pueda ser distribuido.

### Canales Seguros de Contacto
1. **GitHub Private Vulnerability Reporting (Recomendado):**  
   Dirígete a la pestaña **Security** del repositorio, selecciona **Advisories** y haz clic en **"Report a vulnerability"** para abrir un canal privado y cifrado directamente con nuestro equipo de ingeniería.
2. **Correo Electrónico de Seguridad:**  
   Envía los detalles de la vulnerabilidad a:
   📧 **`angel.szymczak+sec@hotmail.com`**

### Información a Incluir en el Reporte
Para acelerar el triaje y la resolución, por favor incluye:
- Descripción clara del tipo de vulnerabilidad (ej. DoS, bypass de autenticación, fuga de tokens, timing attack).
- Pasos reproducibles detallados o código de prueba de concepto (PoC) en Ruby.
- Versión exacta del SDK y versión de Ruby utilizada.
- Evaluación del impacto potencial y severidad estimada (CVSS si aplica).

---

## 3. Acuerdos de Nivel de Servicio (SLA) de Respuesta

Nos comprometemos a actuar con celeridad ante cualquier reporte responsable:

| Fase de Respuesta | Plazo Máximo | Compromiso |
| :--- | :---: | :--- |
| **Acuse de Recibo Inicial** | **< 24 horas** | Confirmación de recepción y asignación de un ingeniero de seguridad. |
| **Evaluación y Triaje** | **< 72 horas** | Reproducción técnica, asignación de severidad CVSS y confirmación de validez. |
| **Desarrollo del Parche (Crítico)** | **< 7 días** | Liberación de parche correctivo y publicación coordinada de GitHub Security Advisory (GHSA). |
| **Desarrollo del Parche (Alto / Medio)** | **< 14 a 30 días** | Corrección programada en el siguiente release semántico. |

---

## 4. Delimitación de Cumplimiento PCI-DSS (SAQ-A Scope Boundary)

El `Payment::SDK` está diseñado específicamente para aislar a las aplicaciones que lo integran dentro del perímetro de menor riesgo de cumplimiento PCI-DSS (**SAQ-A / Self-Assessment Questionnaire A**):

1. **Principio de Tokenización Estricta:**  
   El SDK **nunca** almacena, manipula ni persiste en disco números de tarjeta de crédito/débito crudos (PAN - *Primary Account Number*) ni códigos de seguridad (CVV/CVC). Toda interacción con métodos de pago se realiza mediante identificadores tokenizados opacos (`pm_...`) emitidos directamente por la pasarela de pagos.
2. **Política Zero-PII en Runtime:**  
   Todas las excepciones (`Payment::SDK::ApiError` y subclases) y los adaptadores de logging (`Payment::SDK::Infrastructure::Logging::Sanitizer`) sanitizan de manera determinista encabezados de autorización, claves secretas y cuerpos de respuesta antes de ser emitidos a logs o herramientas de monitoreo (APM, Sentry, Datadog).
3. **Criptografía en Tiempo Constante:**  
   La verificación de firmas de webhooks (`Payment::SDK::Infrastructure::Adapters::Crypto::Signature::Verifier::HmacSha256`) utiliza comparación en tiempo constante (`OpenSSL.fixed_length_secure_compare`) para neutralizar ataques de canal lateral basados en temporización (Timing Attacks).

---

## 5. Divulgación Coordinada y Reconocimiento

- Mantenemos una política de **divulgación coordinada (Coordinated Disclosure)**: solicitamos un período de gracia de 30 a 90 días desde la entrega del reporte para desarrollar, probar y desplegar el parche antes de hacer público el hallazgo.
- Reconocemos públicamente las contribuciones éticas de investigadores de seguridad en nuestras notas de release y en el advisory de seguridad correspondiente, respetando si el investigador prefiere permanecer en el anonimato.
