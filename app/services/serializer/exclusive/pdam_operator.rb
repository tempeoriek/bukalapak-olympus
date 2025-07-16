module Serializer
  module Exclusive
    class PdamOperator
      def initialize(operator)
        @operator = operator
      end

      def as_json(_options = {})
        {
          id: @operator.id,
          name: @operator.name,
          code: @operator.code,
          active: @operator.active?,
          group: @operator.group,
          image_url: @operator.image_url,
          partner: @operator.partner,
          bukalapak_admin_charge: @operator.bukalapak_admin_charge,
          partner_admin_charge: @operator.partner_admin_charge,
          bill_day: "every #{@operator.bill_day}",
          due_day: "every #{@operator.due_day}",
          terms_and_conditions: @operator.terms_and_conditions,
          revenue: @operator.revenue,
          have_issue: @operator.have_issue?,
          update_selling_price: @operator.update_selling_price
        }
      end
    end
  end
end
