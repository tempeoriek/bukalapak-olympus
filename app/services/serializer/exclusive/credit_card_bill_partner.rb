module Serializer
  module Exclusive
    class CreditCardBillPartner
      def initialize(partner)
        @partner = partner
      end

      def as_json(_options = {})
        {
          id: @partner.id,
          name: @partner.name,
          terms_and_conditions: @partner.terms_and_conditions,
          biller_code: @partner.biller_code,
          bukalapak_admin_charge: @partner.bukalapak_admin_charge,
          partner_admin_charge: @partner.partner_admin_charge,
          active: @partner.active?,
          revenue: @partner.revenue,
        }
      end
    end
  end
end
