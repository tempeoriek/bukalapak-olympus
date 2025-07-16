require 'rails_helper'

RSpec.describe Action::PostpaidTransaction::UpdateStatus, type: :model do

  describe '.run!' do
    context 'when status is success or failed' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :processed) }
      let(:response) {
        {
          product: 'electricity_postpaid',
          order_id: 'ELP-12345',
          transaction_id: '2',
          status: 'success',
          info_text: "RINCIAN TAGIHAN DAPAT DIAKSES DI \"www.pln.co.id\" ATAU PLN TERDEKAT"
        }
      }

      let(:partner_object) {
        build_stubbed(:electricity_postpaid_partner, :sepulsa, :active)
      }
      let(:response_generalizer) {
        r = ResponseGeneralizer::ElectricityPostpaid.new(response, partner_object)
        r.status = 2
        r.partner_transaction_id = '2'
        r.info_text =  "RINCIAN TAGIHAN DAPAT DIAKSES DI \"www.pln.co.id\" ATAU PLN TERDEKAT"

        r
      }
      subject { Action::PostpaidTransaction::UpdateStatus.new(transaction, response_generalizer) }
      it 'does not raise error and update transaction status' do
        allow_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        allow_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
        expect { subject.run! }.not_to raise_error
        expect(transaction.state).to eq('partner_succeeded')
        expect(transaction.partner_transaction_id).to eq '2'
      end
    end

    context 'when status is pending' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :processed) }
      let(:response) {
        {
          product: 'electricity_postpaid',
          order_id: 'ELP-12345',
          transaction_id: '2',
          status: 'pending',
          info_text: "RINCIAN TAGIHAN DAPAT DIAKSES DI \"www.pln.co.id\" ATAU PLN TERDEKAT"
        }
      }

      let(:partner_object) {
        build_stubbed(:electricity_postpaid_partner, :sepulsa, :active)
      }
      let(:response_generalizer) {
        r = ResponseGeneralizer::ElectricityPostpaid.new(response, partner_object)
        r.status = 0
        r.partner_transaction_id = '2'
        r.info_text =  "RINCIAN TAGIHAN DAPAT DIAKSES DI \"www.pln.co.id\" ATAU PLN TERDEKAT"

        r
      }
      subject { Action::PostpaidTransaction::UpdateStatus.new(transaction, response_generalizer) }
      it 'raise error' do
        expect { subject.run! }.to raise_error ::Exceptions::InvalidStatusError
        expect(transaction.partner_transaction_id).to eq '2'
      end
    end
  end
end
