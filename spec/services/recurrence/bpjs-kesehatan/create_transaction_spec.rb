require 'rails_helper'

RSpec.describe Recurrence::BpjsKesehatan::CreateTransaction, type: :model do

  let(:recurrence_template) { create(:bpjs_kesehatan_recurrence_template_detail) }
  let(:partner_sepulsa) { build_stubbed(:bpjs_kesehatan_partner) }
  let(:inquiry_response) {
    {
      name: 'SEPULSAWATI (PST:  2)',
      premi: 51000,
      no_va: '0000001430071801',
      periode: '01',
      nama_cabang: 'SEMARANG'
    }
  }
  let(:expected_transaction_data) {
    JSON.parse({
      customer_number: '0000001430071801',
      customer_name: 'SEPULSAWATI',
      admin_charge: 1500,
      amount: 52500,
      state: 'pending'
    }.to_json)
  }
  let(:remote_id) {
    {
      id: 1
    }
  }
  let(:deposit) {
    {
      withdrawable_balance: 40000
    }
  }
  before do
    allow(BpjsKesehatanPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
    allow(Escrow::Connection).to receive(:post).with(anything, anything).and_return(true)
  end

  describe 'run!' do
    context 'success' do
      subject { described_class.new(recurrence_template.id) }

      before do
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
        allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(remote_id)
        allow_any_instance_of(Escrow::RetrieveDeposit).to receive(:run!).and_return(deposit)
        allow_any_instance_of(Recurrence::BpjsKesehatan::Notifier).to receive(:run!).and_return true
        allow(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(false)
      end

      it 'not raising error' do
        expect { subject.run! }.not_to raise_error
      end

      it 'returns correct json' do
        result = subject.run!
        expect(result.as_json).to include(expected_transaction_data)
      end
    end

    context 'failed' do
      context 'no record' do
        subject { described_class.new(recurrence_template.id+1) }
        it 'raise error' do
          expect { subject.run! }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

end
