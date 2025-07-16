module Serializer
  module Internal
    module PdamTransaction
      class Create
        include Postpaid::Constant

        attr_reader :object

        def initialize(object)
          @object = object
        end

        def as_json(_options = {})
          {
            id: object.id,
            buyer_id: object.buyer_id,
            invoice_id: object.invoice_id,
            remote_transaction_id: object.remote_transaction_id,
            customer_number: object.customer_number,
            customer_name: object.customer_name,
            amount: object.amount,
            penalty_fee: object.penalty_fee,
            start_bill_period: object.start_bill_period,
            end_bill_period: object.end_bill_period,
            state: object.state,
            address: object.address,
            usage: object.usage,
            state_changed_at: object.state_changed_at,
            admin_charge: object.admin_charge,
            bills: bills,
            operator: {
              id: object.pdam_operator.id,
              name: object.pdam_operator.name,
              group: object.pdam_operator.group,
              image_url: object.pdam_operator.image_url,
              terms_and_conditions:  object.pdam_operator.terms_and_conditions
            },
            partner: object.partner_hash,
            type: Channel::Config::TRANSACTION_TYPE[PDAM_PRODUCT],
            transaction_type: object.transaction_type,
            revenue: object.pdam_operator.revenue * bills.length
          }.merge!(object.start_end_usage_meter)
        end

        private

        def bills
          object.pdam_bills.map do |bill|
            {
              bill_period: bill.bill_period,
              penalty_fee: bill.penalty_fee,
              amount: bill.amount,
              cubication: bill.cubication,
              tariff: bill.tariff,
              usage: bill.usage
            }
          end
        end
      end
    end
  end
end
