require "rails_helper"

RSpec.describe PdamBill, type: :model do
  let(:biller) { build_stubbed(:pdam_bill) }
  let(:biller_error) { build_stubbed(:pdam_bill, :error_cubication) }
  let(:expected_as_json) {
    {
      'bill_period' => biller.bill_period,
      'penalty_fee' => biller.penalty_fee,
      'amount' => biller.amount,
      'cubication' => biller.cubication,
      'tariff' => biller.tariff,
      'usage' => biller.usage
    }
  }

  describe 'validation' do
    it { expect(biller.valid?).to eq true }
  end

  describe '.usage' do
    context 'return int' do        
      it { expect(biller.usage).to be_a_kind_of(Integer) }  
      it do 
        expect(biller.usage).to eq(1)  
      end
    end

    context 'expect not return error when cubication failed' do 
      it { expect{biller_error.usage}.not_to raise_error }        
    end 
  end

  describe '.as_json' do
    it { expect(biller.as_json).to eq (expected_as_json) }    
  end
end