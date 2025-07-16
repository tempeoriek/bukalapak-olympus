require 'rails_helper'

RSpec.describe Action::BpjsKetenagakerjaanTransaction::UpdateStatus, type: :model do

  let(:transaction) { build(:bpjs_ketenagakerjaan_transaction, :processed) }
  let(:success_response) do
    ResponseGeneralizer::BpjsKetenagakerjaan.new do |r|
      r.status = SUCCESS
      r.partner_transaction_id = 1
      r.reference_number = 'REF-1234'
      r.info = 'some info here'
    end
  end

  let(:failed_response) do
    ResponseGeneralizer::BpjsKetenagakerjaan.new do |r|
      r.status = FAILED
    end
  end

  let(:pending_response) do
    ResponseGeneralizer::BpjsKetenagakerjaan.new do |r|
      r.status = PENDING
    end
  end

  subject { described_class.new(transaction, response) }


  before do
    allow_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
    allow_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
  end

  describe '#run!' do
    context 'when response status is success' do
      let(:response) { success_response }

      it { expect{ subject.run! }.not_to raise_error }
      it 'have expected attributes' do
        transaction = subject.run!
        expect(transaction.info).to eq('some info here')
        expect(transaction.reference_number).to eq('REF-1234')
        expect(transaction.state).to eq('partner_succeeded')
        expect(transaction.partner_transaction_id).to eq '1'
      end
    end

    context 'when response status is failed' do
      let(:response) { failed_response }

      it { expect{ subject.run! }.not_to raise_error }
      it { expect(subject.run!.state).to eq('partner_failed') }
    end

    context 'when response status is neither success nor failed' do
      let(:response) { pending_response }

      it { expect{ subject.run! }.to raise_error(Exceptions::InvalidStatusError) }
    end
  end
end