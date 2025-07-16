require "rails_helper"

RSpec.describe Action::PostpaidTransaction::Confirm, type: :model do
  let(:partner) { build_stubbed(:electricity_postpaid_partner) }
  let(:response_pending) {
    {
      partner_transaction_id: 1,
      status: 0
    }
  }
  let(:response_success) {
    {
      partner_transaction_id: 1,
      status: 2
    }
  }
  let(:response_failed) {
    {
      partner_transaction_id: 1,
      status: 3
    }
  }

  let(:response_generalizer_pending) {
    r = ResponseGeneralizer::ElectricityPostpaid.new(response_pending, partner)
    r.status = 0
    r
  }
  let(:response_generalizer_success) {
    r = ResponseGeneralizer::ElectricityPostpaid.new(response_success, partner)
    r.status = 2
    r
  }
  let(:response_generalizer_failed) {
    r = ResponseGeneralizer::ElectricityPostpaid.new(response_failed, partner)
    r.status = 3
    r
  }
  let(:bukalapak_remit) { "remitted" }
  let(:bukalapak_refunded) { "refunded" }
  let(:transaction) { create(:postpaid_transaction_with_bill, :partner_bukopin, :paid) }
  let(:channel) { Channel::Sepulsa::ElectricityPostpaid.new(transaction) }
  subject { Action::PostpaidTransaction::Confirm.new(transaction) }

  context "transaction pending" do
    it "should raise error if transaction state not process" do
      expect { subject.run! }.to raise_error(Exceptions::CannotConfirmTransaction)
    end
  end

  context "transaction processed" do
    before(:each) do
      allow(Toggles::OlympusSievexSend).to receive(:active?).and_return false
      transaction.process!
      allow(subject).to receive(:partner_channel).and_return(channel)
    end

    it "should raise error if status still pending from partner" do
      allow(channel).to receive(:confirm_transaction).and_return(response_generalizer_pending)
      expect { subject.run! }.to raise_error(Exceptions::InvalidStatusError)
    end

    it "should not error and spawn job update to remit if result success" do
      allow(channel).to receive(:confirm_transaction).and_return(response_generalizer_success)
      expect_any_instance_of(Action::PostpaidTransaction::UpdateStatus).to receive(:run!).and_return true
      expect { subject.run! }.to_not raise_error
    end

    it "should not error and spawn job update to refund if result failed" do
      allow(channel).to receive(:confirm_transaction).and_return(response_generalizer_failed)
      expect_any_instance_of(Action::PostpaidTransaction::UpdateStatus).to receive(:run!).and_return true
      expect { subject.run! }.to_not raise_error
    end

    context 'when transaction type is CreditCardBill and partner is Visa' do
      context 'when failed' do
        let(:biller) { create(:credit_card_biller, :visa, :partner_visa) }
        let(:transaction) {
          create(:cc_transaction, :paid_visa, credit_card_biller_id: biller.id, credit_card_bill_partner_id: biller.partner.id)
        }
        let(:channel) { Channel::Visa::CreditCardBill.new(transaction) }
        let(:response_generalizer_failed) {
          ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = PENDING
          end
        }
        it {
          allow(channel).to receive(:confirm_transaction).and_return(response_generalizer_failed)
          expect { subject.run! }.to raise_error(::Exceptions::Visa::ConfirmFailed)
        }
      end
    end
  end
end
