class PhoneCreditPostpaidRecurrenceTemplateDetail < ApplicationRecord
  def as_json(_options={})
    provider = get_provider
    result = super(
      only: [
        :id,
        :buyer_id,
        :recursive_id,
        :customer_name
      ]
    ).merge({
      'customer_number': phone_number,
      'provider': {
        'name': provider.provider,
        'product_name': provider.product_name,
        'logo_url': provider.logo_url
      }.as_json
    }.as_json)
  end

  def phone_number
    customer_number.to_s.gsub(/^62/, '0')
  end

  private

  def get_provider
    provider_prefix = ProviderPrefix.find_by(prefix: phone_number.to_s[0..4])
    provider_prefix = ProviderPrefix.find_by(prefix: phone_number.to_s[0..3]) if provider_prefix.nil?
    raise ::Exceptions::UnsupportedProvider.new if provider_prefix.nil?
    provider = ::PhoneCreditProvider.find provider_prefix.provider_id
  end
end