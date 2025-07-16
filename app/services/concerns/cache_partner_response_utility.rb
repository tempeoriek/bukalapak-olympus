module CachePartnerResponseUtility
  include ::Postpaid::Constant

  PREFIX_KEY = "cache_partner_response".freeze
  CACHE_TTL = 2.days.to_i.freeze
  ALLOWED_PRODUCT_TYPE = [
    ELECTRICITY_PRODUCT,
    CREDIT_CARD_BILL_PRODUCT,
    PDAM_PRODUCT
  ]

  ## Reference ID can be Customer Number or Transaction ID
  def cache_partner_response(product_type, action, partner, reference_id, response_code)
    return if ALLOWED_PRODUCT_TYPE.exclude? product_type.to_s
    return if response_code.blank? || reference_id.blank?

    key = "#{PREFIX_KEY}::#{product_type}::#{partner}::#{action}::#{reference_id}"

    RedisOlympus.set(key, response_code, ex: CACHE_TTL)
  rescue StandardError
    nil
  end

  def retrieve_partner_response(product_type, action, partner, reference_id)
    return if ALLOWED_PRODUCT_TYPE.exclude? product_type
    return if reference_id.blank?

    key = "#{PREFIX_KEY}::#{product_type}::#{partner}::#{action}::#{reference_id}"

    RedisOlympus.get(key)
  rescue StandardError
    nil
  end
end
