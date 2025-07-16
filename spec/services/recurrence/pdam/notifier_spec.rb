require 'rails_helper'

RSpec.describe Recurrence::Pdam::Notifier, type: :model do
  let(:template_detail) { create(:pdam_recurrence_template_detail) }
  let(:template_detail_id) { template_detail.id }

  let(:template_map) do
    {
      topup_deposit: "olympus_recurrence_topup_deposit_pdam_payload",
      unsubscribe_success: "olympus_recurrence_unsubscribe_success_pdam_payload",
      subscribe_success: "olympus_recurrence_subscribe_success_pdam_payload",
      transaction_success: "olympus_recurrence_transaction_success_pdam_payload",
      transaction_error: "olympus_recurrence_transaction_error_pdam_payload"
    }
  end

  let(:options_map) do
    {
      topup_deposit: { action_date: "2018-08-20" } ,
      unsubscribe_success: {},
      subscribe_success: { action_date: "2018-08-20" },
      transaction_success: { remote_id: expected_remote_id, invoice_id: expected_invoice_id, amount: expected_amount },
      transaction_error: { remote_id: expected_remote_id, invoice_id: expected_invoice_id, amount: expected_amount }
    }
  end

  let(:expected_remote_id) { 123 }
  let(:expected_invoice_id) { 345 }
  let(:expected_amount) { 789 }
  let(:expected_date) { "2018-08-20" }
  let(:expected_payload_map) do
    {
      topup_deposit: {
        product_name: postpaid_product,
        action_date: expected_date,
        operator_name: template_detail.operator.name,
        customer_number: template_detail.customer_number,
        customer_name: template_detail.customer_name
      },
      unsubscribe_success: {
        product_name: postpaid_product,
        action_date: today,
        customer_number: template_detail.customer_number
      },
      subscribe_success: {
        product_name: postpaid_product,
        action_date: expected_date,
        operator_name: template_detail.operator.name,
        customer_number: template_detail.customer_number
      },
      transaction_success: {
        product_name: postpaid_product,
        customer_name: template_detail.customer_name,
        customer_number: template_detail.customer_number,
        action_date: today,
        operator_name: template_detail.operator.name,
        remote_id: expected_remote_id,
        invoice_id: expected_invoice_id,
        amount: expected_amount
      },
      transaction_error: {
        product_name: postpaid_product,
        customer_name: template_detail.customer_name,
        customer_number: template_detail.customer_number,
        action_date: today,
        operator_name: template_detail.operator.name,
        remote_id: expected_remote_id,
        invoice_id: expected_invoice_id,
        amount: expected_amount
      }
    }
  end

  let(:today) { DateTime.strptime("2021-06-03", "%Y-%m-%d") }
  let(:postpaid_product) { 'pdam' }
  let(:options) { {} }

  let(:email_notif_double) { double(Recurrence::Postpaid::EmailNotif) }

  subject { described_class.new(template, template_detail_id, options) }

  before do
    allow(::BpjsKesehatanRecurrenceTemplateDetail).to receive(:find_by).and_return(template_detail)
    allow(Channel::Connection::Http).to receive(:post).and_return(true)
    allow(Date).to receive(:today).and_return today
  end

  describe 'run!' do
    context 'success' do
      before do
        # expect(Recurrence::Postpaid::EmailNotif).to receive(:new).with(template, template_detail.buyer_id, expected_payload).and_return email_notif_double
        expect(Recurrence::Postpaid::EmailNotif).to receive(:new) do |_template, buyer_id, payload|
          expect(_template).to eq template
          expect(buyer_id).to eq template_detail.buyer_id
          expect(payload).to eq expected_payload

          email_notif_double
        end
        expect(email_notif_double).to receive(:run!)
      end

      [
        :topup_deposit,
        :unsubscribe_success,
        :subscribe_success,
        :transaction_success,
        :transaction_error,
      ].each do |notif_type|
        context "#{notif_type}" do
          let(:template) { template_map[notif_type] }
          let(:options) { options_map[notif_type] }
          let(:expected_payload) { expected_payload_map[notif_type] }

          it 'not raising error' do
            subject.run!
            # expect { subject.run! }.not_to raise_error
          end
        end
      end
    end

    context 'when failed' do
      context 'no record' do
        let(:template) { 'olympus_recurrence_topup_deposit_pdam_payload' }
        let(:template_detail_id) { 100 }

        it 'raise error' do
          expect { subject.run! }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'wrong template' do
        let(:template) { 'error_template' }

        it 'raise error' do
          expect { subject.run! }.to raise_error('unsupported notification template')
        end
      end
    end
  end
end
