module PaymentIdHelper
  CACHE_KEY_TEMPLATE = "olympus::transaction::%s::%s::payment_id".freeze
  CACHE_TTL = 2.hours
  INVOICE_API_URL = "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/invoices".freeze

  def payment_id_cache_key(transaction)
    CACHE_KEY_TEMPLATE % [transaction.product_type, transaction.id]
  end

  def cache_payment_id(transaction, payment_id)
    RedisOlympus.set(payment_id_cache_key(transaction), payment_id, ex: CACHE_TTL)
  end

  def get_payment_id(transaction)
    get_payment_id_from_cache(transaction) || get_payment_id_from_api(transaction)
  end

  def get_payment_id_from_cache(transaction)
    RedisOlympus.get(payment_id_cache_key(transaction))
  end

  def get_payment_id_from_api(transaction)
    url = "#{INVOICE_API_URL}/#{transaction.invoice_id}"
    response = Escrow::Connection.get(url)
    JSON.parse(response).dig("data", "payment_id")
  end

  def delete_payment_id(transaction)
    RedisOlympus.del(payment_id_cache_key(transaction))
  end
end
