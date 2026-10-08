# Payment Ruby SDK

A zero-dependency, idiomatic Ruby SDK for the Payment Platform (OpenAPI v1).

## Features
- **Cero Dependencias Externas**: Solo utiliza la librería estándar de Ruby (`net/http`, `openssl`, etc.).
- **Arquitectura Hexagonal (Ports & Adapters)**: Separación clara entre el dominio y la infraestructura.
- **Patrón Inbox Integrado**: Consumo resiliente y seguro de webhooks.
- **Motor de Reconciliación**: Verifica la coherencia de datos locales contra los remotos.
- **CQRS**: Segregación estricta entre lectura (Queries) y escritura (Commands).
- **Retry Automático con Backoff Exponencial**: Resistencia a fallos transitorios de red.
- **Jerarquía de Excepciones Tipeadas**: Manejo robusto de errores mapeados desde la API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'payment-sdk'
```

And then execute:

```bash
$ bundle install
```

## Configuration

Configure the SDK before using it, typically in an initializer (e.g., `config/initializers/payment_sdk.rb`):

```ruby
require 'payment/sdk'

Payment::SDK.configure do |config|
  config.api_key = ENV['PAYMENT_API_KEY']
  config.signing_secret = ENV['PAYMENT_WEBHOOK_SECRET']
  config.base_url = "https://api.payment.com/v1" # Optional (defaults to https://api.payment.com)
  config.timeout = 10                            # Optional (read timeout in seconds)
  config.open_timeout = 5                        # Optional (connection timeout in seconds)
  config.max_retries = 2                         # Optional (number of retries on network errors)
end
```

## Usage

### 1. Client Setup
You can use the default configured client or instantiate your own:

```ruby
client = Payment::SDK::Client.new
```

### 2. Mutations (Commands)
All mutations automatically validate idempotency.

```ruby
# Crear un Payment Intent
intent = client.create_payment_intent(
  amount: 1000,
  currency: "usd",
  merchant_id: "m_123",
  customer_id: "c_123",
  capture_method: "automatic",
  idempotency_key: "my_unique_idempotency_key"
)

# Confirmar
confirmed = client.confirm_payment_intent(
  intent[:id],
  payment_method_token: "pm_card_visa",
  idempotency_key: "conf_key_123"
)
```

### 3. Inspections (Queries)
```ruby
intent = client.get_payment_intent("pi_123")
lifecycle = client.get_payment_lifecycle("pi_123")
```

### 4. Resilient Webhooks (Inbox Pattern)

The SDK provides a built-in mechanism to process webhooks resiliently. You must provide an object that responds to `apply!(inbox_entry:)` to perform your business logic. The SDK will handle HMAC validation, idempotency, and state transition.

```ruby
class MyPaymentProjection
  def apply!(inbox_entry:)
    payload = JSON.parse(inbox_entry[:raw_payload])
    # Apply changes to your database
    # ActiveRecord::Base.transaction { ... }
  end
end

begin
  result = client.process_webhook(
    payload: raw_request_body,
    signature_header: request.headers["X-Payment-Signature"],
    projection: MyPaymentProjection.new
  )
  puts result[:status] # => :processed or :duplicate
rescue Payment::SDK::SignatureVerificationError => e
  # Handle invalid signatures (HTTP 400/401)
rescue StandardError => e
  # Projection failed, the event is saved as :failed for later retry
end
```
> **Nota**: Por defecto, el `Client` usa un `InMemoryInboxStore`. Para producción, debes inyectar tu propio adaptador que implemente `Payment::SDK::Domain::Ports::InboxStorePort` (por ejemplo, con `ActiveRecord`).

### 5. Reconciliation Engine

The SDK can automatically reconcile your local projections with the remote truth to detect "drift" (status mismatch, amount discrepancy, etc.) without mutating your business data.

```ruby
local_records = [
  { payment_intent_id: "pi_123", status: "requires_payment_method", amount: 1000 }
]

reconciliation_results = client.reconcile(
  local_records: local_records,
  run_id: "run_#{Time.now.to_i}"
)

reconciliation_results.each do |result|
  if result[:status] != :match
    puts "Drift Detected for #{result[:payment_intent_id]}: #{result[:status]}"
  end
end
```

## Error Handling

All specific errors inherit from `Payment::SDK::Error`.

- `Payment::SDK::NetworkError`: Network failures (after max retries).
- `Payment::SDK::TimeoutError`: Connection or read timeouts.
- `Payment::SDK::ApiError`: Parent class for all API errors.
  - `Payment::SDK::InvalidRequestError` (HTTP 400)
  - `Payment::SDK::PaymentNotFoundError` (HTTP 404)
  - `Payment::SDK::DuplicateRequestError` (HTTP 409 - Idempotency conflict)
  - `Payment::SDK::PaymentDeclinedError` (Business rejections)
  - `Payment::SDK::UpstreamError` (HTTP 500)
- `Payment::SDK::SignatureVerificationError`: Webhook signature mismatch or expiration.

## License

MIT License.
