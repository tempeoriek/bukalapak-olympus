require "rails_helper"

RSpec.describe Action::PostpaidTransaction::EmailNotif, type: :model do
  let(:transaction) { create(:postpaid_transaction_with_bill, :partner_succeeded) }
  let(:user_detail_url) { "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/users/id/%s".freeze }
  let(:user_detail) {
    {
      data: {
        id: transaction.buyer_id,
        username: 'alisa',
        name: 'Alina Stravoska',
        email: 'alisa@russie.com',
        phone: 'xxxxxxxx',
      }
    }.to_json
  }
  let(:invoice_detail_url) { "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/invoices/%s".freeze }
  let(:invoice_detail) {
    {
      data: {
        id: transaction.invoice_id,
        buyer_id: transaction.buyer_id,
        payment_id: "BL16A1B2C3DINV",
        amount: {
          total: 42123,
          details: {
            transactions: 80000,
            payment: 123,
            promo_payment: -5000,
            voucher: -20000,
            wallet: -10000,
            priority_buyer: -4000,
            partner_reductions: -19000,
            buffer: 0
          }
        },
        payment_type: "transfer",
      }
    }.to_json
  }

  describe 'O2OVPD-884: #run!' do
    let(:provider) { build_stubbed(:phone_credit_provider) }
    
    before do
      allow(PhoneCreditProvider).to receive(:find).and_return(provider)
      expect(Toggles::EmailNotif).to receive(:active?).and_return(true)
      expect(Escrow::Connection).to receive(:get).with(user_detail_url % transaction.buyer_id ).and_return(user_detail)
      expect(Escrow::Connection).to receive(:get).with(invoice_detail_url % transaction.invoice_id ).and_return(invoice_detail)
      expect(Channel::Connection::Http).to receive(:post)
    end

    subject { described_class.new(transaction) }

    context 'when object is electricity postpaid transaction with state partner_succeeded' do
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is pdam transaction with state partner_succeeded' do
      let(:transaction) { build(:pdam_transaction_with_bill, :partner_succeeded) }
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is phone credit postpaid transaction with state partner_succeeded' do
      let(:transaction) { build(:phone_credit_postpaid_transaction, :partner_succeeded) }
      let(:provider) { build(:phone_credit_provider) }
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is bpjs kesehatan transaction with state partner_succeeded' do
      let(:transaction) { build(:bpjs_kesehatan_transaction, :partner_succeeded) }
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is credit card bill transaction with state partner_succeeded' do
      let(:transaction) { build(:cc_transaction, :partner_succeeded) }
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is bpjs ketenagakerjaan transaction with state partner_succeeded' do
      let(:transaction) { build(:bpjs_ketenagakerjaan_transaction, :partner_succeeded) }
      it { expect { subject.run! }.not_to raise_error }
    end

    # FAILED
    context 'when object is electricity postpaid transaction with state partner_failed' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :partner_failed) }
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is pdam transaction with state partner_failed' do
      let(:transaction) { build(:pdam_transaction_with_bill, :partner_failed) }
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is phone credit postpaid transaction with state partner_failed' do
      let(:transaction) { build(:phone_credit_postpaid_transaction, :partner_failed) }
      let(:provider) { build(:phone_credit_provider) }
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is bpjs kesehatan transaction with state partner_failed' do
      let(:transaction) { build(:bpjs_kesehatan_transaction, :partner_failed) }
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is credit card bill transaction with state partner_failed' do
      let(:transaction) { build(:cc_transaction, :partner_failed) }
      it { expect { subject.run! }.not_to raise_error }
    end

    context 'when object is bpjs ketenagakerjaan transaction with state partner_failed' do
      let(:transaction) { build(:bpjs_ketenagakerjaan_transaction, :partner_failed) }
      it { expect { subject.run! }.not_to raise_error }
    end
  end
end
