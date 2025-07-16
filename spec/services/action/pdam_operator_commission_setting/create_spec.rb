require "rails_helper"

RSpec.describe Action::PdamOperatorCommissionSetting::Create, type: :model do

  let(:params) do
    {
        operator_id: 1,
        value: 1000,
        state: 'active',
        min_transaction_value: 1,
        max_transaction_value: 100
    }
  end
  let(:operator) { build_stubbed(:pdam_operator) }
  let(:setting) { build_stubbed(:pdam_operator_commission_setting) }

  let(:form) { Form::PdamOperatorCommissionSetting.new(params) }

  subject { described_class.new(form) }

  describe 'O2OVPE-1019: #run!' do
    context 'when operator not found' do
        before do
            allow(PdamOperator).to receive(:find).and_return(nil)
        end

        it 'raises error' do
            expect{ subject.run! }.to raise_error ::Exceptions::OperatorNotFound
        end
    end

    context 'when successful' do
        before do
            allow(PdamOperator).to receive(:find).and_return(operator)
            allow(PdamOperatorCommissionSetting).to receive(:new).and_return(setting)
            allow(setting).to receive(:save!).and_return true
        end

        it 'does not raise error' do
            result = subject.run!
            expect(result.value).to eq(setting.value)
            expect(result.pdam_operator_id).to eq(setting.pdam_operator_id)
            expect(result.state).to eq(setting.state)
            expect(result.min_transaction_value).to eq(setting.min_transaction_value)
            expect(result.max_transaction_value).to eq(setting.max_transaction_value)
        end
    end
  end
end
