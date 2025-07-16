module Serializer
  module Exclusive
    class BpjsKesehatanPartner
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
          state: partner.state,
          revenue: partner.revenue,
        }
      end
    end
  end
end
