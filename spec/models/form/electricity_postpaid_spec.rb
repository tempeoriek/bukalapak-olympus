# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Form::ElectricityPostpaid, type: :form do
  let(:customer_number) { 512345610000 }
  let(:expected_customer_number) { 512345610000 }
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin) }
  let(:partner_tektaya) { build_stubbed(:electricity_postpaid_partner, :tektaya) }
  let(:partner_ayoconnect) { build_stubbed(:electricity_postpaid_partner, :ayoconnect) }

  describe '#initialize' do
    subject { Form::ElectricityPostpaid }

    it 'does not throw error' do
      expect{ subject.new(customer_number) }.not_to raise_error
    end

    context 'with whitelisted user for ayoconnect' do
      subject { Form::ElectricityPostpaid.new(customer_number, 'testing1') }

      it 'chooses correct partner ayoconnect' do
        expect(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'ayoconnect').and_return(partner_ayoconnect)
        subject
      end
    end

    context 'with whitelisted user for bukopin' do
      subject { Form::ElectricityPostpaid.new(customer_number, 'alsoncahyadi') }

      it 'chooses correct partner bukopin' do
        expect(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'bukopin').and_return(partner_bukopin)
        subject
      end
    end

    context 'with whitelisted user for tektaya' do
      subject { Form::ElectricityPostpaid.new(customer_number, 'vladimirputin') }

      it 'chooses tektaya partner' do
        expect(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'tektaya').and_return(partner_tektaya)
        expect(subject.partner_object).to eq(partner_tektaya)

        subject
      end
    end
  end

  describe '#customer_number' do
    subject { Form::ElectricityPostpaid.new(customer_number) }
    it 'returns correct customer number' do
      expect(subject.customer_number).to eq(expected_customer_number)
    end
  end

  describe '#partner' do
    before do
      allow(ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
      allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'bukopin').and_return(partner_bukopin)
      allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'sepulsa').and_return(partner_sepulsa)
      allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'ayoconnect').and_return(partner_ayoconnect)
    end

    it 'choose correct partner bukopin' do
      expect(Form::ElectricityPostpaid.new(customer_number, 'NO_USERNAME', 'bukopin').partner_object).to eq(partner_bukopin)
    end

    it 'choose correct partner sepulsa' do
      expect(Form::ElectricityPostpaid.new(customer_number, 'NO_USERNAME', 'sepulsa').partner_object).to eq(partner_sepulsa)
    end

    it 'choose correct partner ayoconnect' do
      expect(Form::ElectricityPostpaid.new(customer_number, 'NO_USERNAME', 'ayoconnect').partner_object).to eq(partner_ayoconnect)
    end

    it 'choose default active partner' do
      expect(Form::ElectricityPostpaid.new(customer_number).partner_object).to eq(partner_sepulsa)
    end

    describe '#is_mitra?' do
      context 'when buyer is agent and partner is not bukaconnect' do
        it 'return value is true' do
          expect(Form::ElectricityPostpaid.new(customer_number, nil, nil, AGENT_BUYER_TYPE).is_mitra?).to be_truthy
        end
      end

      context 'when buyer is normal and partner is not bukaconnect' do
        it 'return value is false' do
          expect(Form::ElectricityPostpaid.new(customer_number, nil, nil, NORMAL_BUYER_TYPE).is_mitra?).to be false
        end
      end

      context 'when buyer is collecting agent and partner is not bukaconnect' do
        it 'return value is true' do
          expect(Form::ElectricityPostpaid.new(customer_number, nil, nil, COLLECTING_AGENT_BUYER_TYPE).is_mitra?).to be true
        end
      end
    end

    describe '#is_bukaconnect?' do
      context 'when buyer is collecting agent and partner is not bukaconnect' do
        it 'return value is true' do
          expect(Form::ElectricityPostpaid.new(customer_number, nil, nil, COLLECTING_AGENT_BUYER_TYPE).is_bukaconnect?).to be false
        end
      end

      context 'when buyer is agent and partner is not bukaconnect' do
        it 'return value is false' do
          expect(Form::ElectricityPostpaid.new(customer_number, nil, nil, AGENT_BUYER_TYPE).is_bukaconnect?).to be false
        end
      end

      context 'when buyer is normal and partner is not bukaconnect' do
        it 'return value is false' do
          expect(Form::ElectricityPostpaid.new(customer_number, nil, nil, NORMAL_BUYER_TYPE).is_bukaconnect?).to be false
        end
      end
    end
  end
end
