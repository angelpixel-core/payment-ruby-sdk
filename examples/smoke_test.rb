# frozen_string_literal: true

require "payment/sdk"

Payment::SDK.configure do |config|
  config.api_key = "sk_test_12345"
  config.signing_secret = "whsec_test_secret"
  config.base_url = "https://api.payment.com/v1"
end

client = Payment::SDK::Client.new

# Mock HTTP logic for smoke test
class MockHttpAdapter
  def request(method:, path:, headers: {}, body: nil, query_params: {})
    case path
    when "/payment_intents"
      {
        id: "pi_#{rand(1000..9999)}",
        amount: body[:amount],
        currency: body[:currency],
        status: "requires_payment_method"
      }
    when %r{^/payment_intents/(pi_\d+)/confirm$}
      {
        id: $1,
        status: "succeeded",
        amount: body[:amount] || 1000
      }
    when "/reports/transactions"
      query_params[:view] == "snapshot" ? [
        { payment_intent_id: "pi_123", status: "succeeded", amount: 1000 }
      ] : []
    else
      raise "Unknown mock endpoint"
    end
  end
end

# Override client adapter with Mock
client.instance_variable_set(:@http_client, MockHttpAdapter.new)

puts "=== Smoke Test Iniciado ==="

puts "\n[1] Creando Payment Intent..."
intent = client.create_payment_intent(
  amount: 1000,
  currency: "usd",
  merchant_id: "m_123",
  customer_id: "c_123",
  capture_method: "automatic",
  idempotency_key: "ik_#{Time.now.to_i}"
)
puts "  -> Creado exitosamente: #{intent.inspect}"

puts "\n[2] Confirmando Payment Intent..."
confirmed_intent = client.confirm_payment_intent(
  intent[:id],
  payment_method_token: "pm_card_visa",
  idempotency_key: "ik_conf_#{Time.now.to_i}"
)
puts "  -> Confirmado exitosamente: #{confirmed_intent.inspect}"

puts "\n[3] Simulando Recepción de Webhook..."
timestamp = Time.now.to_i
payload = %Q({"delivery_id":"del_001","event_id":"evt_001","event_type":"payment_intent.succeeded","data":{"object":{"id":"#{confirmed_intent[:id]}"}}})
signature = OpenSSL::HMAC.hexdigest("SHA256", "whsec_test_secret", "#{timestamp}.#{payload}")
signature_header = "t=#{timestamp},v1=#{signature}"

class DummyProjection
  def apply!(inbox_entry:)
    puts "      (Projection aplicó los cambios a la BD en base al payload: #{inbox_entry[:raw_payload]})"
  end
end

result = client.process_webhook(
  payload: payload,
  signature_header: signature_header,
  projection: DummyProjection.new
)
puts "  -> Webhook procesado exitosamente en estado: #{result[:status]}"

puts "\n[4] Reconciliando Transacciones..."
local_records = [
  { payment_intent_id: "pi_123", status: "requires_payment_method", amount: 1000 }
]

reconciliation_results = client.reconcile(
  local_records: local_records,
  run_id: "run_#{Time.now.to_i}"
)

puts "  -> Reporte de drift:"
reconciliation_results.each do |r|
  puts "     - #{r[:payment_intent_id]}: #{r[:status]}"
end

puts "\n=== Smoke Test Completado ==="
