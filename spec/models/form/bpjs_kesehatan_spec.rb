require 'rails_helper'

RSpec.describe Form::BpjsKesehatan, type: :model do
  let(:customer_number){ '0123123123' }
  let(:payment_period){ '01' }
  let(:invalid_payment_period){ '00' }
  let(:today) { Time.now }
  let(:month) { today.month }
  let(:year) { today.year }

  let(:invalid_month) { today.month }
  let(:invalid_year) { year-1 }

  let(:invalid_month_2) { 13 }
  let(:invalid_year_2) { year }

  let(:invalid_month_3) { 12 }
  let(:invalid_year_3) { year+1 }

  context "passing payment period directly" do
    it "not raise error if valid payment period" do
      expect{Form::BpjsKesehatan.new(customer_number, payment_period)}.not_to raise_error
    end

    it "raise error if not valid payment period" do
      expect{Form::BpjsKesehatan.new(customer_number, invalid_payment_period)}.to raise_error(::Exceptions::InvalidPaymentPeriod)
    end
  end

  context "passing month and year" do
    it "not raise error if valid payment period" do
      expect{Form::BpjsKesehatan.new(customer_number, nil, month, year)}.not_to raise_error
    end

    it "raise error if not valid paid until" do
      expect{Form::BpjsKesehatan.new(customer_number, nil, invalid_month, invalid_year)}.to raise_error(::Exceptions::InvalidPaymentPeriod)
    end

    it "raise error if not valid paid until 2" do
      expect{Form::BpjsKesehatan.new(customer_number, nil, invalid_month_2, invalid_year_2)}.to raise_error(::Exceptions::InvalidPaymentPeriod)
    end

    it "raise error if not valid paid until 3" do
      expect{Form::BpjsKesehatan.new(customer_number, nil, invalid_month_3, invalid_year_3)}.to raise_error(::Exceptions::InvalidPaymentPeriod)
    end

    context "attribute value" do
      before do
        allow(Time).to receive(:now).and_return(Time.new(2017, 5))
      end

      it "set correct value" do
        form = Form::BpjsKesehatan.new(customer_number, nil, 7,2017)
        expect(form.payment_period).to eq("03")
        expect(form.customer_number).to eq(customer_number)
      end
    end
  end

  describe '#is_mitra' do
    it 'return value is true' do
      expect(Form::BpjsKesehatan.new(customer_number, payment_period, nil, nil, AGENT_BUYER_TYPE).is_mitra?).to be_truthy
    end

    it 'return value is false' do
      expect(Form::BpjsKesehatan.new(customer_number, payment_period, nil, nil, NORMAL_BUYER_TYPE).is_mitra?).to be false
    end
  end
end
