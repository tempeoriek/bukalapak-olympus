require "rails_helper"

RSpec.describe Form::PhoneCreditProvider, type: :form do
  let(:params) {
    {
      active: true
    }
  }
  let(:expected_params) { { active: true } } 
  let(:instance_phone_credit) { Form::PhoneCreditProvider.new(params) }
  

  describe '#initialize' do
    subject { described_class }
    it 'does not throw error' do
      expect{subject.new(params)}.not_to raise_error
    end
  end

  describe '#create_params' do
    subject { described_class.new(params) }
    it 'returns correct customer number' do
      expect(instance_phone_credit.create_params).to eq(expected_params)
    end
  end

  describe '#update_params' do
    subject { described_class.new(params) }
    it 'returns correct customer number' do
      expect(instance_phone_credit.update_params).to eq(expected_params)
    end 
  end
end
