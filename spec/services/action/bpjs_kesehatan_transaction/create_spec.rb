require "rails_helper"

RSpec.describe Action::BpjsKesehatanTransaction::Create, type: :model do
  let(:customer_number) { '0000001430071801' }
  let(:payment_period) { '01' }
  let(:buyer_id) { 1 }
  let(:phone_number) { '081234567890' }
  let(:form) { Form::BpjsKesehatan.new(customer_number, payment_period) }
  subject { Action::BpjsKesehatanTransaction::Create.new(form, buyer_id, phone_number, 0) }
  let(:invalid_inquiry) {
    r = ResponseGeneralizer::BpjsKesehatan.new
    r.customer_number = '0000001430071801'
    r.bukalapak_admin_charge = 1000
    r.partner_admin_charge = 500
    r
  }
  let(:valid_inquiry) do
    r = ResponseGeneralizer::BpjsKesehatan.new
    r.customer_number = '0000001430071801'
    r.customer_name = 'ANISA KARTIKA INDIARTI'
    r.family_member_count = 1
    r.branch_name = 'SEMARANG'
    r.amount = 51000
    r.bukalapak_admin_charge = 1000
    r.partner_admin_charge = 500
    r.payment_period = '02'
    r.partner_transaction_id = '1234'
    r.partner = 'sepulsa'
    r
  end

  let(:expected_paid_until) { "2017-10" }

  context "get inquiry" do
    it "should inquire again" do
      expect_any_instance_of(Action::PostpaidTransaction::Inquiry).to receive(:run!).and_return(valid_inquiry)

      expect(subject.send(:get_inquiry)).to eq(valid_inquiry)
    end
  end

  context "create transaction" do
    it "should raise error if inquiry cache is not valid" do
      allow(subject).to receive(:get_inquiry).and_return(invalid_inquiry)

      expect { subject.run! }.to raise_error(Exceptions::CreateTransactionError)
    end

    it "should not raise error if inquiry cache is valid" do
      allow(subject).to receive(:get_inquiry).and_return(valid_inquiry)
      expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
        id: 1
      })

      expect { subject.run! }.not_to raise_error
    end

    it "should return the expected paid until" do
      allow(subject).to receive(:get_inquiry).and_return(valid_inquiry)
      allow(Time.zone).to receive_message_chain(:now, :month).and_return(9)
      allow(Time.zone).to receive_message_chain(:now, :year).and_return(2017)
      allow_any_instance_of(Action::PostpaidTransaction::Create).to receive(:save_transaction!) do |transaction|
        transaction
      end
      response_transaction = subject.run!
      expect(response_transaction["paid_until"]).to eq(expected_paid_until)
    end
  end
end
