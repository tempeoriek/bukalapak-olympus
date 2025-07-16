module Serializer
  module Exclusive
    class ElectricityPostpaidPartner
      attr_reader :partner

      def initialize(partner)
        @partner = partner
      end

      def as_json(_options = {})
        {
          id: partner.id,
          name: partner.name,
          partner_admin_charge: partner.partner_admin_charge,
          bukalapak_admin_charge: partner.bukalapak_admin_charge,
          bukalapak_commission: partner.bukalapak_commission,
          state: partner.state,
          balance: partner.electricity_postpaid_partners_balances.map { |balance| Serializer::Exclusive::ElectricityPostpaidPartnersBalance.new(balance) },
          partner_type: partner.partner_type
        }
      end
    end
  end
end
