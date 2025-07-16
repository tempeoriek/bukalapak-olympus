module Serializer
  module Exclusive
    class CreditCardBiller
      def initialize(biller)
        @biller = biller
      end

      def as_json(_options = {})
        {
          id: @biller.id,
          name: @biller.name,
          image_url: @biller.image_url,
          partners: @biller.partners.map { |partner| Serializer::Exclusive::CreditCardBillPartner.new(partner) },
          active: @biller.active?,
        }
      end
    end
  end
end
