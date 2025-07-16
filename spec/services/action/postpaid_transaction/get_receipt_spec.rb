require "rails_helper"

RSpec.describe Action::PostpaidTransaction::GetReceipt, type: :model do
  let(:transaction) { create(:postpaid_transaction_with_bill, :partner_succeeded) }
  let(:bpjs_kesehatan_transaction) { create(:bpjs_kesehatan_transaction, :partner_succeeded, :with_paid_at, :with_info) }
  let(:bpjs_ketenagakerjaan_transaction) { create(:bpjs_ketenagakerjaan_transaction, :partner_succeeded) }
  let(:type) { 'png' }
  let(:invoice_detail_url) { "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/invoices/%s".freeze }
  let(:invoice_detail) {
    {
      data: {
        id: transaction.invoice_id,
        buyer_id: transaction.buyer_id,
        payment_id: "BL16A1B2C3DINV",
        voucher_code: "BLJAJAN",
        amount: {
          total: 35623,
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
        payment_type_details: {
          name: 'Transfer Bank'
        }
      }
    }.to_json
  }

  describe 'O2OVPD-884: #run!' do
    subject { described_class.new(transaction, type) }
    context 'electricity postpaid transaction' do
      before do
        expect(Escrow::Connection).to receive(:get).with(invoice_detail_url % transaction.invoice_id).and_return(invoice_detail)
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('pdf mock')
        allow_any_instance_of(IMGKit).to receive(:to_img).and_return('png mock')
      end

      context 'return base64 image string when type is png' do
        it { expect{subject.run!}.not_to raise_error }
        it { expect(subject.run!).to be_a(String) }
      end

      context 'return hash with pdf when type is pdf' do
        let(:type) { 'pdf' }
        it { expect{subject.run!}.not_to raise_error }
        it { expect(subject.run!).to be_a(Hash) }
      end

      context 'not raising error when paid_at is nil' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :partner_succeeded, paid_at: nil) }
        let(:type) { 'pdf' }
        it { expect{subject.run!}.not_to raise_error }
      end
    end

    context 'bpjs kesehatan transaction' do
      subject { described_class.new(bpjs_kesehatan_transaction, type) }
      before do
        expect(Escrow::Connection).to receive(:get).with(invoice_detail_url % bpjs_kesehatan_transaction.invoice_id).and_return(invoice_detail)
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('pdf mock')
        allow_any_instance_of(IMGKit).to receive(:to_img).and_return('png mock')
      end

      context 'return base64 image string when type is png' do
        it { expect{subject.run!}.not_to raise_error }
        it { expect(subject.run!).to be_a(String) }
      end

      context 'return hash with pdf when type is pdf' do
        let(:type) { 'pdf' }
        it { expect{subject.run!}.not_to raise_error }
        it { expect(subject.run!).to be_a(Hash) }
      end

      context 'not raising error when paid_at is nil' do
        let(:bpjs_kesehatan_transaction) { create(:bpjs_kesehatan_transaction, :partner_succeeded, :with_paid_at, :with_info, paid_at: nil) }
        let(:type) { 'pdf' }
        it { expect{subject.run!}.not_to raise_error }
      end
    end

    context 'with bpjs ketenagakerjaan transaction' do
      subject { described_class.new(bpjs_ketenagakerjaan_transaction, type) }
      before do
        expect(Escrow::Connection).to receive(:get).with(invoice_detail_url % bpjs_ketenagakerjaan_transaction.invoice_id).and_return(invoice_detail)
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('pdf mock')
        allow_any_instance_of(IMGKit).to receive(:to_img).and_return('png mock')
      end

      context 'when type is png' do
        it { expect{subject.run!}.not_to raise_error }
        it { expect(subject.run!).to be_a(String) }
      end

      context 'when type is pdf' do
        let(:type) { 'pdf' }
        it { expect{subject.run!}.not_to raise_error }
        it { expect(subject.run!).to be_a(Hash) }
      end

      context 'when type is txt' do
        let(:type) { 'txt' }
        it { expect{subject.run!}.to raise_error(Exceptions::UnsupportedType) }
      end

      context 'when paid_at is nil' do
        let(:bpjs_ketenagakerjaan_transaction) { create(:bpjs_ketenagakerjaan_transaction, :partner_succeeded, paid_at: nil) }
        let(:type) { 'pdf' }
        it { expect{subject.run!}.not_to raise_error }
      end
    end

    describe 'failed #run!' do
      subject { described_class.new(transaction, type) }
      context 'error when transaction not succeed' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :processed) }
        it { expect{subject.run!}.to raise_error(Exceptions::InvalidStatusError) }
      end

      context 'error when transaction not succeed' do
        let(:type) { 'string' }
        before { expect(Escrow::Connection).to receive(:get).with(invoice_detail_url % transaction.invoice_id).and_return(invoice_detail) }
        it { expect{subject.run!}.to raise_error(Exceptions::UnsupportedType) }
      end
    end
  end
end
