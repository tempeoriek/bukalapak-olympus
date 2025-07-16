require 'rails_helper'

RSpec.describe Action::BpjsKetenagakerjaanTransaction::Create, type: :model do
  let(:customer_number) { '1871010907930009' }
  let(:payment_period) { 1 }
  let(:buyer_id) { 1 }
  let(:form) { Form::BpjsKetenagakerjaan.new(customer_number, payment_period) }
  subject { Action::BpjsKetenagakerjaanTransaction::Create.new(form, buyer_id, 0) }

  let(:valid_inquiry) {
    ResponseGeneralizer::BpjsKetenagakerjaan.new.tap do |result|
      result.bills = [{
        amount: 36800,
        jht: 20000,
        jkk: 10000,
        jkm: 6800
      }]
      result.partner = 'ayoconnect'
      result.customer_number = '1871010907930009'
      result.customer_name = 'NICO JULIAN'
      result.bpjs_tk_type = 'bpu'
      result.bukalapak_admin_charge = 1000
      result.partner_admin_charge = 2000
      result.amount = 38300
      result.payment_period = 1
      result.start_bill_period = '2021-08-27'
      result.end_bill_period = '2021-09-26'
      result.npp = nil
      result.division = nil
      result.bill_code = 'N/A'
      result.reference_number = nil
      result.branch_name = 'JAKARTA GROGOL'
      result.unpaid_bills = false
      result.unpaid_bills_text = ''
    end
  }
  let(:invalid_inquiry) {
    ResponseGeneralizer::BpjsKetenagakerjaan.new.tap do |result|
      result.customer_number = '1871010907930009'
      result.customer_name = 'NICO JULIAN'
      result.bukalapak_admin_charge = 1000
      result.partner_admin_charge = 2000
    end
  }

  let(:valid_inquiry_with_unpaid_bills) do
    response_generalizer = valid_inquiry
    response_generalizer.bill_code = '921083112662'
    response_generalizer.unpaid_bills = true
    response_generalizer.unpaid_bills_text = 'Total Iuran diatas merupakan nominal dari kode iuran yang belum terbayarkan sebelumnya.'

    response_generalizer
  end

  context "when request get inquiry" do
    it "should inquire again" do
      expect_any_instance_of(Action::PostpaidTransaction::Inquiry).to receive(:run!).and_return(valid_inquiry)
      expect(subject.send(:get_inquiry)).to eq(valid_inquiry)
    end
  end

  context "when request create transaction" do
    it "should raise error if inquiry cache is not valid" do
      allow(subject).to receive(:get_inquiry).and_return(invalid_inquiry)

      expect { subject.run! }.to raise_error(Exceptions::CreateTransactionError)
    end

    context 'with unpaid bills transaction' do
      it "should not raise error if inquiry cache is valid" do
        allow(subject).to receive(:get_inquiry).and_return(valid_inquiry_with_unpaid_bills)
        expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
          id: 1
        })

        result = subject.run!
        expect { result }.not_to raise_error
        expect(result.unpaid_bills).to be_truthy
      end
    end

    context 'without unpaid bills' do
      it "should not raise error if inquiry cache is valid" do
        allow(subject).to receive(:get_inquiry).and_return(valid_inquiry)
        expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
          id: 1
        })
  
        result = subject.run!
        expect { result }.not_to raise_error
        expect(result.unpaid_bills).to be_falsy
      end
    end
  end
end