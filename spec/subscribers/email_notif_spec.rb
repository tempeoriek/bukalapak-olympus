require 'rails_helper'
require 'support/pubsub_mocks'

describe Subscribers::EmailNotif do
  include_context 'pubsub_mocks'
  include Postpaid::Constant

  let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :succeeded) }
  let(:message) {
    {
      remote_id: transaction.remote_transaction_id,
      product_type: transaction.product_type
    }.to_json
  }

  it 'not raise_error' do
    expect(PostpaidTransaction).to receive(:find_by_remote_transaction_id).and_return(transaction)
    expect(Keystore).to receive(:get).with(ELECTRICITY_EMAIL_TELOLET_TOGGLE).and_return(true)
    expect(Keystore).not_to receive(:get).with(EMAIL_TELOLET_TOGGLE)
    expect_any_instance_of(Action::PostpaidTransaction::EmailNotif).to receive(:run!)

    expect{ described_class.run }.not_to raise_error
  end

  context 'with pdam transaction' do
    let(:transaction) { build(:pdam_transaction_with_bill, :succeeded) }

    it 'run email notif service without raising_error' do
      expect(PdamTransaction).to receive(:find_by_remote_transaction_id).and_return(transaction)
      expect(Keystore).to receive(:get).with(ELECTRICITY_EMAIL_TELOLET_TOGGLE).and_return(true)
      expect(Keystore).to receive(:get).with(EMAIL_TELOLET_TOGGLE).and_return(true)
      expect_any_instance_of(Action::PostpaidTransaction::EmailNotif).to receive(:run!)

      expect{ described_class.run }.not_to raise_error
    end

    it 'run escrow without raising_error' do
      expect(PdamTransaction).to receive(:find_by_remote_transaction_id).and_return(transaction)
      expect(Keystore).to receive(:get).with(ELECTRICITY_EMAIL_TELOLET_TOGGLE).and_return(false)
      expect(Keystore).to receive(:get).with(EMAIL_TELOLET_TOGGLE).and_return(false)
      expect_any_instance_of(Escrow::SendNotification).to receive(:run!)

      expect{ described_class.run }.not_to raise_error
    end
  end

  context 'with reccuring transaction' do
    let(:expected_template_id) { transaction.template_detail_id }
    let(:expected_options) { { amount: transaction.amount, remote_id: transaction.id, invoice_id: transaction.invoice_id } }
    let(:notifier_double) { double('Recurrence::ElectricityPostpaid::Notifier') }

    before do
      allow(Keystore).to receive(:get).with(ELECTRICITY_EMAIL_TELOLET_TOGGLE).and_return(true)
      allow(Keystore).to receive(:get).with(EMAIL_TELOLET_TOGGLE).and_return true
    end

    # for each supported recurring product
    [
      {
        name: 'postpaid_electricity',
        klass: PostpaidTransaction,
        notifier_klass: Recurrence::ElectricityPostpaid::Notifier,
        factory_name: :postpaid_transaction_with_bill
      },
      {
        name: 'pdam',
        klass: PdamTransaction,
        notifier_klass: Recurrence::Pdam::Notifier,
        factory_name: :pdam_transaction_with_bill
      },
      {
        name: 'bpjs_kesehatan',
        klass: BpjsKesehatanTransaction,
        notifier_klass: Recurrence::BpjsKesehatan::Notifier,
        factory_name: :bpjs_kesehatan_transaction
      }
    ].each do |product|
      context "with #{product[:name]} transaction" do

        # for each supported state
        [:succeeded, :failed, :partner_succeeded, :partner_failed, :cancelled].each do |state|
          context "with state #{state}" do
            let(:transaction) { build_stubbed(product[:factory_name], :recurrent, state) }
            let(:state_template) { BL_STATE_TO_TEMPLATE_MAP[TRX_STATE_TO_BL_STATE_MAP[state]] }
            let(:expected_template) { "olympus_recurrence_transaction_#{state_template}_#{product[:name]}_payload" }

            before do
              expect(product[:klass]).to receive(:find_by_remote_transaction_id).and_return(transaction)
            end

            it 'not raise_error' do
              expect_any_instance_of(Action::PostpaidTransaction::EmailNotif).not_to receive(:run!)
              expect(product[:notifier_klass]).to receive(:new).and_return notifier_double
              expect(notifier_double).to receive(:run!)

              expect{ described_class.run }.not_to raise_error
            end
          end
        end
      end
    end
  end
end
