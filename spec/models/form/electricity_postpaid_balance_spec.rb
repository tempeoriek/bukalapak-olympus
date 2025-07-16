require "rails_helper"

RSpec.describe Form::ElectricityPostpaidBalance, type: :form do
  let(:customer_number) { 512345610000 }
  let(:expected_customer_number) { 512345610000 }
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin) }

  let(:params) {
    {
      balance: 100_000,
      threshold: 50_000,
      type: 'bukalapak'
    }
  }

  describe '#initialize' do
    subject { described_class }

    context 'correct parameter' do
      it 'does not throw error' do
        expect{ subject.new(params) }.not_to raise_error
      end
    end

    context 'invalid parameter' do
      context 'invalid balance' do
        let(:params) {
          {
            threshold: 50_000,
            type: 'bukalapak'
          }
        }

        it 'does not throw error' do
          expect{ subject.new(params) }.to raise_error
        end
      end

      context 'invalid threshold' do
        let(:params) {
          {
            balance: 100_000,
            type: 'bukalapak'
          }
        }

        it 'does not throw error' do
          expect{ subject.new(params) }.to raise_error
        end
      end

      context 'invalid type' do
        let(:params) {
          {
            balance: 100_000,
            threshold: 50_000,
            type: 'bukapedia'
          }
        }

        it 'does not throw error' do
          expect{ subject.new(params) }.to raise_error
        end
      end
    end
  end

  describe '#mitra?' do

    subject { described_class }
    context 'mitra type' do
      let(:params) {
        {
          balance: 100_000,
          threshold: 50_000,
          type: 'mitra'
        }
      }
      it 'returns true' do
        expect(subject.new(params).mitra?).to eq(true)
      end
    end

    context 'bukalapak type' do
      it 'returns false' do
        expect(subject.new(params).mitra?).to eq(false)
      end
    end
  end
end
