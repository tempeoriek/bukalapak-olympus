require 'rails_helper'

RSpec.describe Action::PdamTransaction::CalculateCommission do
  let(:transaction) { double('Transaction', pdam_operator_id: 1, amount: 500_000) }
  let(:commission_setting) { double('CommissionSetting', value: 0.05, min_transaction_value: 100_000, max_transaction_value: 1_000_000, state: 'active') }

  before do
    allow(::PdamOperatorCommissionSetting).to receive_message_chain(:where, :order, :all).and_return([commission_setting])
  end

  describe 'O2OVPE-1070: #run!' do
    context 'when there are commission settings' do
      it 'returns the selected commission setting' do
        calculate_commission = described_class.new(transaction)
        selected_setting = calculate_commission.run!

        expect(selected_setting).to eq(commission_setting)
      end
    end

    context 'when there are no commission settings' do
        before do
            allow(::PdamOperatorCommissionSetting).to receive_message_chain(:where, :order, :all).and_return([])
        end

        it 'returns a new commission setting with value 0' do
            calculate_commission = described_class.new(transaction)
            selected_setting = calculate_commission.run!

            expect(selected_setting.value).to eq(0)
        end
    end
  end

  describe '#amount' do
    it 'returns the transaction amount' do
      calculate_commission = described_class.new(transaction)
      amount = calculate_commission.amount

      expect(amount).to eq(500_000)
    end
  end
end