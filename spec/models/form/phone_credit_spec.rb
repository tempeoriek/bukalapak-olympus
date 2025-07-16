require "rails_helper"

RSpec.describe Form::PhoneCredit, type: :form do
  let(:customer_number) { '081234000001' }
  let(:provider) { build_stubbed :phone_credit_provider }
  let(:provider_prefix) { build_stubbed :provider_prefix }
  let(:expected_customer_number) { '081234000001' }

  before do
    allow(ProviderPrefix).to receive(:find_by).with(prefix: customer_number[0..4]).and_return(nil)
    allow(ProviderPrefix).to receive(:find_by).with(prefix: customer_number[0..3]).and_return(provider_prefix)
    allow(PhoneCreditProvider).to receive(:find).and_return(provider)
  end

  describe '#initialize' do
    it 'does not throw error' do
      expect{ described_class.new(customer_number) }.not_to raise_error
    end

    context 'when phone number invalid' do
      let(:customer_number) { '0812e34000001' }

      it 'raise error' do
        expect{ described_class.new(customer_number) }.to raise_error(Exceptions::InvalidPhoneNumber)
      end
    end

    context 'when provider not supported' do
      it {
        allow(ProviderPrefix).to receive(:find_by).with(prefix: customer_number[0..3]).and_return nil
        expect{ described_class.new(customer_number) }.to raise_error(Exceptions::UnsupportedProvider)
      }
    end

    context 'when provider not active' do
      let(:provider) { build_stubbed :phone_credit_provider, :inactive }
      it {
        expect{ described_class.new(customer_number) }.to raise_error(Exceptions::InactiveProvider)
      }
    end
  end

  describe '#customer_number' do
    subject { described_class.new(customer_number) }
    it 'returns correct customer number' do
      expect(subject.customer_number).to eq(expected_customer_number)
    end
  end

  describe '#is_mitra' do
    it 'return value is false' do
      expect(Form::PhoneCredit.new(customer_number, nil).is_mitra?).to be false
    end
  end
end
