require 'rails_helper'
require 'support/electricity_mocks'

RSpec.describe Action::ElectricityTransaction::UpdateStatus, type: :model do
  include_context 'electricity_mocks'

  let(:electricity_transaction) { build(:postpaid_transaction_with_bill, :processed, :partner_bukopin) }

  subject { described_class.new(electricity_transaction, response_generalizer) }

  before do
    allow_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
    allow_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
  end
  describe '#run!' do
    context 'when response status is success' do
      let(:response_generalizer) { success_response }
      it { expect{ subject.run! }.not_to raise_error }
      it 'have expected attributes' do
        expect(Action::ElectricityTransaction::Exclusive::DeductBalance).to receive(:new).with(kind_of(PostpaidTransaction)).and_call_original
        transaction = subject.run!
        expect(transaction.reference_number).to eq('ABC123')
        expect(transaction.state).to eq('partner_succeeded')
        expect(transaction.partner_transaction_id).to eq '1'
        expect(transaction.segmentation).to eq 'R1M'
        expect(transaction.power).to eq 900
        expect(transaction.stand_meter).to eq("00047824-000048084")
      end
    end

    context 'when response status is failed' do
      let(:response_generalizer) { failed_response }
      it { expect{ subject.run! }.not_to raise_error }
      it { expect(subject.run!.state).to eq('partner_failed') }
      it 'have expected attributes' do
        transaction = subject.run!
        expect(transaction.info_text).to eq('Transaksi gagal')
        expect(transaction.state).to eq('partner_failed')
      end
    end

    context 'when response status is neither success nor failed' do
      let(:response_generalizer) { pending_response }
      it { expect{ subject.run! }.to raise_error(Exceptions::InvalidStatusError) }
    end
  end
end
