require 'rails_helper'
require 'json'

RSpec.describe Escrow::SendNotification, type: :model do
  context 'request' do
    context 'electricity_postpaid' do
      before do
        allow_any_instance_of(Escrow::SendNotification).to receive(:parse_response)
      end

      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :succeeded) }
      let(:template) { EMAIL_TEMPLATE[transaction.class][transaction.state] }

      it 'send correct payload' do
        object = Escrow::SendNotification.new(transaction)
        expect(Escrow::Connection).to receive(:post).with(
          any_args,
          hash_including(
            template: template,
            user_ids: [transaction.buyer_id],
            postpaid_electricity_payload: [
              {
                remote_id: transaction.remote_transaction_id,
                customer_number: transaction.customer_number,
                customer_name: transaction.customer_name,
                segmentation: transaction.segmentation,
                power: transaction.power,
                period: transaction.period,
                amount: transaction.amount,
                admin_charge: transaction.admin_charge,
                penalty_fee: transaction.penalty_fee,
                stand_meter: transaction.stand_meter,
                info_text: transaction.info_text,
                reference_number: transaction.reference_number,
                partner_name: transaction.partner,
                outstanding_bill: transaction.outstanding_bill,
                unpaid_bill: transaction.unpaid_bill
              }
            ]
          )
        )
        object.run!
      end
    end

    context 'bpjs_kesehatan' do
      before do
        allow_any_instance_of(Escrow::SendNotification).to receive(:parse_response)
      end

      let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction, :succeeded) }
      let(:template) { EMAIL_TEMPLATE[transaction.class][transaction.state] }

      it 'send correct payload' do
        object = Escrow::SendNotification.new(transaction)
        expect(Escrow::Connection).to receive(:post).with(
          any_args,
          hash_including(
            template: template,
            user_ids: [transaction.buyer_id],
            bpjs_kesehatan_payload: [
              {
                remote_id: transaction.remote_transaction_id,
                customer_number: transaction.customer_number,
                customer_name: transaction.customer_name,
                branch_name: transaction.branch_name,
                admin_charge: transaction.admin_charge,
                family_member_count: transaction.family_member_count,
                payment_period: transaction.payment_period,
                paid_until: transaction.paid_until,
                family_members: transaction.family_members.as_json,
                info: transaction.info,
                partner_name: transaction.partner,
                reference_number: transaction.reference_number
              }
            ]
          )
        )
        object.run!
      end
    end

    context 'pdam' do
      before do
        allow_any_instance_of(Escrow::SendNotification).to receive(:parse_response)
      end

      let(:transaction) { build_stubbed(:pdam_transaction_with_bill, :succeeded) }
      let(:template) { EMAIL_TEMPLATE[transaction.class][transaction.state] }

      it 'send correct payload' do
        object = Escrow::SendNotification.new(transaction)
        expect(Escrow::Connection).to receive(:post).with(
          any_args,
          hash_including(
            template: template,
            user_ids: [transaction.buyer_id],
            pdam_payload: [
              {
                remote_id: transaction.remote_transaction_id,
                operator_name: transaction.pdam_operator.name,
                customer_number: transaction.customer_number,
                customer_name: transaction.customer_name,
                amount: transaction.amount,
                start_period: transaction.period.first,
                end_period: transaction.period.last,
                usage: transaction.usage,
                address: transaction.address,
                admin_charge: transaction.admin_charge,
                bills: transaction.pdam_bills.as_json,
                start_usage_meter: 1,
                end_usage_meter: 4
              }
            ]
          )
        )
        object.run!
      end
    end

    context 'phone_credit' do
      before do
        allow(PhoneCreditProvider).to receive(:find).and_return(provider)
        allow_any_instance_of(Escrow::SendNotification).to receive(:parse_response)
      end

      let(:provider) { build_stubbed(:phone_credit_provider) }
      let(:transaction) { build_stubbed(:phone_credit_postpaid_transaction, :succeeded) }
      let(:template) { EMAIL_TEMPLATE[transaction.class][transaction.state] }

      it 'send correct payload' do
        object = Escrow::SendNotification.new(transaction)
        expect(Escrow::Connection).to receive(:post).with(
          any_args,
          hash_including(
            template: template,
            user_ids: [transaction.buyer_id],
            phone_credit_postpaid_payload: [
              {
                remote_id: transaction.remote_transaction_id,
                customer_number: transaction.phone_number,
                customer_name: transaction.customer_name,
                provider_name: transaction.provider.provider,
                provider_product_name: transaction.provider.product_name,
                reference_no: transaction.reference_no,
                start_period: transaction.start_bill_period,
                end_period: transaction.end_bill_period
              }
            ]
          )
        )
        object.run!
      end
    end
  end
end
