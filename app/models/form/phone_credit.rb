module Form
  class PhoneCredit < Base
    attr_accessor :customer_number, :provider, :buyer_id, :buyer_type

    def initialize(customer_number, buyer_id = nil, buyer_type = NORMAL_BUYER_TYPE)
      @customer_number = validate_phone_number customer_number
      @provider = get_provider
      @buyer_id = buyer_id
      @buyer_type = buyer_type
    end

    def customer_number
      @customer_number
    end

    def provider
      @provider
    end

    def is_mitra?
      @buyer_type == AGENT_BUYER_TYPE || @buyer_type == COLLECTING_AGENT_BUYER_TYPE
    end

    private

    def validate_phone_number(phone_number)
      phone_number.tr!('-','')
      return phone_number if phone_number =~ /\A99[0-9]{8,14}\z/ # Bolt number format
      return phone_number if phone_number =~ /\A0[0-9]{9,15}\z/
      if phone_number =~ /\A8[0-9]{8,14}\z/
        return "0#{phone_number}"
      elsif phone_number =~ /\A62[0-9]{9,15}\z/
        return "0#{phone_number[2..-1]}"
      elsif phone_number =~ /\A\+62[0-9]{9,15}\z/
        return "0#{phone_number[3..-1]}"
      else
        raise ::Exceptions::InvalidPhoneNumber.new
      end
    end

    def get_provider
      provider_prefix = ProviderPrefix.find_by(prefix: customer_number[0..4])
      provider_prefix = ProviderPrefix.find_by(prefix: customer_number[0..3]) if provider_prefix.nil?
      raise ::Exceptions::UnsupportedProvider.new if provider_prefix.nil?
      provider = ::PhoneCreditProvider.find provider_prefix.provider_id
      raise ::Exceptions::InactiveProvider.new unless provider.active?
      provider
    end
  end
end
