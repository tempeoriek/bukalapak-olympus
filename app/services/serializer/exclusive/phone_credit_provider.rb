module Serializer
  module Exclusive
    class PhoneCreditProvider
      def initialize(provider)
        @provider = provider
      end

      def as_json(_options = {})
        {
          id: @provider.id,
          name: @provider.provider,
          product_name: @provider.product_name,
          logo_url: @provider.logo_url,
          active: @provider.active,
          partner_admin_charge: @provider.partner_admin_charge,
          bukalapak_admin_charge: @provider.bukalapak_admin_charge,
          bukalapak_commission: @provider.bukalapak_commission,
        }
      end
    end
  end
end
