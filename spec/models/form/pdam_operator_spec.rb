require 'rails_helper'

RSpec.describe Form::PdamOperator, type: :form do
  let(:params) do
    {
      active: true
    }
  end
  let(:expected_params) { { active: 1, have_issue: 0 } }

  describe 'O2OVPD-1358: #initialize' do
    subject { described_class }
    it 'does not throw error' do
      expect { subject.new(params) }.not_to raise_error
    end
  end

  describe '#create_params' do
    subject { described_class.new(params) }
    it 'returns correct create params' do
      expect(subject.create_params).to eq(expected_params)
    end
  end

  describe '#update_params' do
    subject { described_class.new(params) }

    context 'when have_issue not present in params' do
      it 'returns correct update params' do
        expect(subject.update_params).to eq(expected_params)
      end
    end

    context 'when have_issue present in params' do
      let(:params) { { active: true, have_issue: true } }
      it 'returns correct update params' do
        expect(subject.update_params).to eq(expected_params.merge!(have_issue: 1))
      end
    end
  end
end
