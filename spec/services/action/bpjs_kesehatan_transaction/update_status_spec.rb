require 'rails_helper'
require 'support/bpjs_kesehatan_mocks'

RSpec.describe Action::BpjsKesehatanTransaction::UpdateStatus, type: :model do
  include_context 'bpjs_kesehatan_mocks'

  subject { described_class.new(bpjs_transaction, bpjs_response_generalizer) }

  before do
    allow_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
    allow_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
  end
  describe '#run!' do
    context 'when response status is success' do
      let(:bpjs_response_generalizer) { success_response }

      it { expect{ subject.run! }.not_to raise_error }
      it 'have expected attributes' do
        transaction = subject.run!
        expect(transaction.info).to eq('HUBUNGI KANTOR BPJS KESEHATAN TERDEKAT UNTUK INFO LEBIH LANJUT')
        expect(transaction.reference_number).to eq('ABC123')
        expect(transaction.state).to eq('partner_succeeded')
        expect(transaction.partner_transaction_id).to eq '1'
      end
    end

    context 'when response status is failed' do
      let(:bpjs_response_generalizer) { failed_response }
      it { expect{ subject.run! }.not_to raise_error }
      it { expect(subject.run!.state).to eq('partner_failed') }
    end

    context 'when response status is neither success nor failed' do
      let(:bpjs_response_generalizer) { pending_response }
      it { expect{ subject.run! }.to raise_error(Exceptions::InvalidStatusError) }
    end
  end
end
