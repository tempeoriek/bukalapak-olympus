require 'rails_helper'

RSpec.describe Recurrence::Pdam::CreateTransaction, type: :model do
  let(:recurrence_template) { create(:pdam_recurrence_template_detail) }
  let(:pdam_operator) { build_stubbed(:pdam_operator, :sepulsa) }
  let(:deposit) { { withdrawable_balance: 40000 } }
  let(:inquiry_response) { build(:sepulsa_response, :pdam_inquiry) }
  let(:expected_transaction_data) {
    JSON.parse({
      remote_transaction_id: 1,
      customer_number: '1998800007',
      customer_name: 'Putin',
      penalty_fee: 10000,
      admin_charge: (2 * Test::ADMIN_CHARGE),
      amount: 187_000,
      state: 'pending'
    }.to_json)
  }
  let(:remote_id) {
    {
      id: 1
    }
  }
  before do
    allow(PdamOperator).to receive(:find_by).with(id: recurrence_template.operator_id).and_return(pdam_operator)
    allow_any_instance_of(PdamTransaction).to receive(:operator).and_return(pdam_operator)
    allow(Escrow::Connection).to receive(:post).with(anything, anything).and_return(true)
    allow(::Toggle::PdamAutoswitch)
      .to receive(:active?)
      .and_return(true)
  end

  describe 'run!' do
    context 'success' do
      subject { described_class.new(recurrence_template.id) }

      before do
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
        allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(remote_id)
        allow_any_instance_of(Escrow::RetrieveDeposit).to receive(:run!).and_return(deposit)
      end

      it 'does not raise error' do
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
