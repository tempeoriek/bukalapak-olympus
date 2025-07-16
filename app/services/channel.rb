# frozen_string_literal: true

module Channel
  # Constants (for electricity postpaid partners)
  ELECTRICITY_POSTPAID_SEPULSA_PARTNER_NAMES    = %w[sepulsa sepulsa_bukaconnect]
  ELECTRICITY_POSTPAID_BUKOPIN_PARTNER_NAMES    = %w[bukopin bukopin_bukaconnect]
  ELECTRICITY_POSTPAID_AYOCONNECT_PARTNER_NAMES = %w[ayoconnect ayoconnect_bukaconnect]
  ELECTRICITY_POSTPAID_TEKTAYA_PARTNER_NAMES    = %w[tektaya tektaya_bukaconnect]
  ELECTRICITY_POSTPAID_THOR_PARTNER_NAMES       = %w[vsi_thor sat_thor]
  PDAM_THOR_PARTNER_NAMES = %w[vsi_thor mkm_thor fortuna_thor bms_thor]

  class << self
    def new_partner_channel(object)
      case object
      when Form::ElectricityPostpaid, PostpaidTransaction
        if ELECTRICITY_POSTPAID_SEPULSA_PARTNER_NAMES.include?(object.partner_object.name)
          Channel::Sepulsa::ElectricityPostpaid.new(object)
        elsif ELECTRICITY_POSTPAID_BUKOPIN_PARTNER_NAMES.include?(object.partner_object.name)
          Channel::Bukopin::ElectricityPostpaid.new(object)
        elsif ELECTRICITY_POSTPAID_AYOCONNECT_PARTNER_NAMES.include?(object.partner_object.name)
          Channel::Ayoconnect::ElectricityPostpaid.new(object)
        elsif ELECTRICITY_POSTPAID_TEKTAYA_PARTNER_NAMES.include?(object.partner_object.name)
          Channel::Tektaya::ElectricityPostpaid.new(object)
        elsif ELECTRICITY_POSTPAID_THOR_PARTNER_NAMES.include?(object.partner_object.name)
          Channel::Thor::ElectricityPostpaid.new(object)
        else
          raise ::Exceptions::PartnerClassNotFound
        end
      when Form::BpjsKesehatan, BpjsKesehatanTransaction
        if object.partner_object.name == 'sepulsa'
          Channel::Sepulsa::BpjsKesehatan.new(object)
        elsif object.partner_object.name == 'dji-bpjs'
          Channel::Dji::BpjsKesehatan.new(object)
        end
      when Form::PhoneCredit, PhoneCreditPostpaidTransaction
        Channel::Sepulsa::PhoneCredit.new(object)
      when Form::Pdam, PdamTransaction
        if object.partner == 'sepulsa'
          Channel::Sepulsa::Pdam.new(object)
        elsif object.partner == 'dji' || object.partner == 'dji-pdam-to'
          Channel::Dji::Pdam.new(object)
        elsif PDAM_THOR_PARTNER_NAMES.include?(object.partner)
          Channel::Thor::Pdam.new(object)
        end
      when Form::CreditCardBill, CreditCardBillTransaction
        case object.partner.name.to_sym
        when :bni
          if whitelist_new_bni_active?(object) || ::Toggle::CreditCardBill::NewBNI.active?
            Channel::NewBNI::CreditCardBill.new(object)
          else
            Channel::BNI::CreditCardBill.new(object)
          end
        when :pnl
          Channel::Pnl::CreditCardBill.new(object)
        when :visa
          Channel::Visa::CreditCardBill.new(object)
        when :cimbniaga_thor
          Channel::Thor::CreditCardBill.new(object)
        end
      when Form::BpjsKetenagakerjaan, BpjsKetenagakerjaanTransaction
        case object.partner_object.name.to_sym
        when :ayoconnect
          Channel::Ayoconnect::BpjsKetenagakerjaan.new(object)
        end
      else
        raise 'Unsupported type'
      end
    end

    # We can't whitelist by username on form because only the channel differs for BNI.
    # And we can't use username to whitelist because transaction doesn't have usernames.
    # So, we whitelist by using user IDs.
    def whitelist_new_bni_active?(object)
      ::Toggle::CreditCardBill::WhitelistNewBNI.active? && WhitelistNewBniUserIds.include?(object&.buyer_id.to_s)
    end
  end
end
