require "rails_helper"

RSpec.describe Form::Pdam, type: :form do
  let(:customer_number) { "1998900001" }
  let(:operator_id) { "1" }
  let(:operator_id_selected) { "120" }
  let(:unauthorized_username) { "dummy_username" }
  let(:operator) { build_stubbed(:pdam_operator) }
  let(:operator_selected) { build_stubbed(:pdam_operator, :selected_area_code) }
  let(:pdam) { Form::Pdam }
  let(:pdam_instance) { Form::Pdam.new(customer_number, operator_id) }
  let(:pdam_instance_whitelist) { Form::Pdam.new(customer_number, operator_id) }

  describe '#initialize' do
    context 'when operator is valid' do
      it 'does not throw error' do
        allow(PdamOperator).to receive(:find_by_id).with(operator_id).and_return(operator)
        expect{ pdam.new(customer_number, operator_id) }.not_to raise_error
      end
    end

    context 'when operator is invalid' do
      it 'throws an error' do
        allow(PdamOperator).to receive(:find_by_id).with(operator_id).and_return(nil)
        expect{ pdam.new(customer_number, operator_id) }.to raise_error(Exceptions::InvalidPdamOperator)
      end
    end

    context 'when unauthorized username access affected operator' do
      it 'throws an error' do
        allow(PdamOperator).to receive(:find_by_id).with(operator_id_selected).and_return(operator_selected)
        expect{ pdam.new(customer_number, operator_id_selected, unauthorized_username) }.to raise_error(Exceptions::InvalidPdamOperator)
      end
    end
  end

  before(:each) do
    allow(PdamOperator).to receive(:find_by_id).with(operator_id).and_return(operator)
  end

  describe '#customer_number' do
    it { expect(pdam_instance.customer_number).to eq(customer_number) }
  end

  describe '#operator_id' do
    it { expect(pdam_instance.operator_id).to eq(operator_id) }
  end

  describe '#operator' do
    it { expect(pdam_instance.operator).to eq(operator) }
  end

  describe '#is_mitra' do
    it 'return value is true' do
      expect(Form::Pdam.new(customer_number, operator_id, nil, AGENT_BUYER_TYPE).is_mitra?).to be_truthy
    end

    it 'return value is false' do
      expect(Form::Pdam.new(customer_number, operator_id, nil, NORMAL_BUYER_TYPE).is_mitra?).to be false
    end
  end
end
