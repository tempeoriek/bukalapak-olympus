module Serializer
  module Internal
    module ElectricityPostpaidTransaction
      class Show
        include Postpaid::Constant

        attr_reader :object

        def initialize(object)
          @object = object
        end

        def as_json(_options = {})
          {
            id: object.id,
            invoice_id: object.invoice_id,
            remote_transaction_id: object.remote_transaction_id,
            reference_number: object.reference_number,
            customer_number: object.customer_number,
            customer_name: object.customer_name,
            stand_meter: object.stand_meter,
            segmentation: object.segmentation,
            power: object.power,
            outstanding_bill: object.outstanding_bill,
            unpaid_bill: object.unpaid_bill,
            penalty_fee: object.penalty_fee,
            admin_charge: object.admin_charge,
            amount: object.amount,
            state: object.state,
            info_text: object.info_text,
            processed_at: object.processed_at,
            succeeded_at: object.succeeded_at,
            failed_at: object.failed_at,
            period: object.period,
            partner_name: object.partner,
            partner: object.partner_hash,
            type: Channel::Config::TRANSACTION_TYPE[ELECTRICITY_PRODUCT],
            bills: object.bills.as_json({only: [
              :bill_period,
              :penalty_fee,
              :amount
            ]}),
            image_url: object.image_url,
            transaction_type: object.transaction_type,
            state_changed_at: object.state_changed_at,
            revenue: object.bukalapak_commission,
            response_code: object.response_code,
            failed_reason: object.failed_reason
          }
        end
      end
    end
  end
end
