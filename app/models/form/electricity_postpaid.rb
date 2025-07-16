# frozen_string_literal: true

module Form
  class ElectricityPostpaid < Base
    attr_accessor :customer_number, :partner_object, :buyer_type, :mass_bill_id

    DEFAULT_USERNAME = 'NO_USERNAME'

    def initialize(customer_number, username=::Form::ElectricityPostpaid::DEFAULT_USERNAME, partner=nil, buyer_type = NORMAL_BUYER_TYPE, mass_bill_id = nil)
      @customer_number = customer_number
      @buyer_type = buyer_type
      if partner.present?
        @partner_object = ::ElectricityPostpaidPartner.find_by(name: partner)
      elsif Toggles::WhitelistBukopin.active? && WhitelistBukopin.include?(username)
        @partner_object = ::ElectricityPostpaidPartner.find_by(name: ::Postpaid::Constant::BUKOPIN)
      elsif Toggles::WhitelistAyoConnect.active? && WhitelistAyoConnect.include?(username)
        @partner_object = ::ElectricityPostpaidPartner.find_by(name: ::Postpaid::Constant::AYOCONNECT)
      elsif Toggles::WhitelistTektaya.active? && WhitelistTektaya.include?(username)
        @partner_object = ::ElectricityPostpaidPartner.find_by(name: ::Postpaid::Constant::TEKTAYA)
      else
        @partner_object = ::ElectricityPostpaidPartner.find_by(state: ::Postpaid::Constant::ACTIVE_PARTNER)
      end
      @buyer_type = buyer_type
      @mass_bill_id = mass_bill_id
    end

    def mitra_buyer_type?
      @buyer_type == AGENT_BUYER_TYPE
    end

    def bukaconnect_buyer_type?
      @buyer_type == COLLECTING_AGENT_BUYER_TYPE
    end

    def is_mitra?
      mitra_buyer_type? || (bukaconnect_buyer_type? && !@partner_object.bukaconnect_partner?)
    end

    def is_bukaconnect?
      bukaconnect_buyer_type? && @partner_object.bukaconnect_partner?
    end
  end
end
