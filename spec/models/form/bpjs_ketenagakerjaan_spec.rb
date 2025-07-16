require 'rails_helper'

RSpec.describe Form::BpjsKetenagakerjaan, type: :model do
  let(:pu_customer_number){ '210800004501' }
  let(:bpu_customer_number){ '1871010907930009' }
  let(:invalid_customer_number){ '123456' }
  let(:payment_period){ 1 }
  let(:invalid_payment_period){ 0 }

  describe '#initialize' do
    context 'when payment period is valid' do
      it 'does not raise an error' do
        expect{Form::BpjsKetenagakerjaan.new(pu_customer_number, payment_period)}.not_to raise_error
      end
    end

    context 'when payment period is invalid' do
      it 'raises an error' do
        expect{Form::BpjsKetenagakerjaan.new(pu_customer_number, invalid_payment_period)}.to raise_error(::Exceptions::InvalidPaymentPeriod)
      end
    end

    context 'when customer number is for BPU' do
      it 'does not raise an error' do
        expect{Form::BpjsKetenagakerjaan.new(bpu_customer_number, payment_period)}.not_to raise_error
      end

      it 'sets correct bpjs_tk_type' do
        form = Form::BpjsKetenagakerjaan.new(bpu_customer_number, payment_period)
        expect(form.bpjs_tk_type).to eq(:bpu)
      end
    end

    context 'when customer number is for PU' do
      it 'does not raise an error' do
        expect{Form::BpjsKetenagakerjaan.new(pu_customer_number, payment_period)}.not_to raise_error
      end

      it 'sets correct bpjs_tk_type' do
        form = Form::BpjsKetenagakerjaan.new(pu_customer_number, payment_period)
        expect(form.bpjs_tk_type).to eq(:pu)
      end
    end

    context 'when customer number is not for BPU nor PU' do
      it 'raises an error' do
        expect{Form::BpjsKetenagakerjaan.new(invalid_customer_number, payment_period)}.to raise_error(::Exceptions::InvalidCustomerNumber)
      end
    end
  end

  describe '#is_mitra' do
    it 'return value is true' do
      expect(Form::BpjsKetenagakerjaan.new(bpu_customer_number, payment_period, AGENT_BUYER_TYPE).is_mitra?).to be_truthy
    end

    it 'return value is false' do
      expect(Form::BpjsKetenagakerjaan.new(bpu_customer_number, payment_period, NORMAL_BUYER_TYPE).is_mitra?).to be false
    end
  end
end
