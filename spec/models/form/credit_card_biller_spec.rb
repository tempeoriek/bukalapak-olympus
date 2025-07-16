require 'rails_helper'

RSpec.describe Form::CreditCardBiller, :credit_card_bill, type: :model do
  let(:params) {
    {
      name: "BNI",
      images_url: 'https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png',
      active: true,
    }
  }
  let(:expected_params) {
    {
      name: "BNI",
      images_url: 'https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png',
      active: 1,
    }
  }

  subject { described_class.new(params) }

  describe 'create_params' do
    context 'active biller' do
      it { expect(subject.create_params).to eq expected_params }
    end
    context 'inactive biller' do
      let(:params) {
        {
          name: "BNI",
          images_url: 'https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png',
          active: false,
        }
      }
      let(:expected_params) {
        {
          name: "BNI",
          images_url: 'https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png',
          active: 0,
        }
      }
      it { expect(subject.create_params).to eq expected_params }
    end
  end

  describe 'update_params' do
    context 'active biller' do
      it { expect(subject.update_params).to eq expected_params }
    end
    context 'inactive biller' do
      let(:params) {
        {
          name: "BNI",
          images_url: 'https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png',
          active: false,
        }
      }
      let(:expected_params) {
        {
          name: "BNI",
          images_url: 'https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png',
          active: 0,
        }
      }
      it { expect(subject.update_params).to eq expected_params }
    end
  end
end
