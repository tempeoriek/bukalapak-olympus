require 'rails_helper'

RSpec.describe Form::ElectricityPostpaidPartner, type: :model do
  let(:parameters) {
      {
          active: true,
          partner: 'bni'
      }
  }

  let(:expected_params) {
      {
          active: true,
          partner: 'bni',
      }
  }

  subject { described_class.new(parameters) }

  context '#create_params' do
    it 'create electricity postpaid partner form' do
      expect(subject.create_params).to eq expected_params
    end
    it 'create electricity postpaid partner even when active nil' do
      expect(subject.update_params).to eq expected_params
    end
  end
end
