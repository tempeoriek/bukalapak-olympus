module Form
  class CreditCardBill < Base
    attr_accessor :customer_number, :biller, :biller_id, :user_id, :partner, :amount, :card_data, :buyer_type, :buyer_id

    BANK_ISSUER_URL = "#{ENV['BUKALAPAK_WEB_URL']}/payment/payments/get_banks"

    def initialize(customer_number, biller_id, amount=0, buyer_type = NORMAL_BUYER_TYPE, username: nil, buyer_id: nil)
      @customer_number = customer_number
      @amount = amount.to_i
      @biller_id = biller_id.to_i
      @username = username
      @buyer_type = buyer_type
      @biller = ::CreditCardBiller.find @biller_id
      raise ::Exceptions::BillerNotFound.new if @biller.nil? || !@biller.active?
      raise ::Exceptions::InvalidCreditCardNumberLength.new unless valid_digit?
      raise ::Exceptions::InvalidCreditCardNumber.new unless Luhn.valid? customer_number
      raise ::Exceptions::Visa::InvalidVisaCard.new unless valid_visa_card?
      raise ::Exceptions::AmountExceedsLimit.new if @amount && @amount > 50_000_000
      raise ::Exceptions::BillerUnavailable.new unless whitelist_bni?
      raise ::Exceptions::BillerUnavailable.new unless whitelist_visa?
      # raise ::Exceptions::InvalidBankIssuer.new unless valid_bank_issuer?
      @biller = biller
      @partner = biller.partner
      @buyer_id = buyer_id
    end

    # def valid_bank_issuer?
    #   url = "#{BANK_ISSUER_URL}/#{@customer_number}"
    #   response = Escrow::Connection.get(url, {}, {host: "www.local.host:5000"})
    #   result = JSON.parse(response).with_indifferent_access
    #   response["bank"].upcase == @biller.biller_code.upcase
    # end

    def valid_digit?
      detector = CreditCardValidations::Detector.new(@customer_number)
      detector.valid?
    end

    def whitelist_bni?
      return true unless Toggles::WhitelistBni.active?
      return true unless @biller.partner.name == 'bni'
      @username && WhitelistBni.include?(@username)
    end

    def whitelist_visa?
      return true unless Toggles::WhitelistVisa.active?
      return true unless visa?
      @username && WhitelistVisa.include?(@username)
    end

    def visa?
      @biller.partner.name.downcase == 'visa'
    end

    def valid_visa_card?
      if visa?
        @customer_number[0] == '4'
      else
        true
      end
    end

    def is_mitra?
      @buyer_type == AGENT_BUYER_TYPE
    end
  end
end
