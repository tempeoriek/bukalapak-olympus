require "rails_helper"
include Postpaid::Constant

RSpec.describe Channel::Pnl::Base, type: :model do
  # Biller & partner
  let(:cc_partner) { build_stubbed(:credit_card_bill_partner, :pnl) }
  let(:cc_biller) { build_stubbed(:credit_card_biller, :bni, :partner_pnl) }

  # Customer credentials
  let(:customer_number) { '5426400930034274' }
  let(:biller_id) { 1 }
  let(:auth) { Channel::Pnl::Base::AUTH }

  # Trx
  let(:cc_trx_paid) { build_stubbed(:cc_transaction, :paid, credit_card_biller: cc_biller) }
  let(:cc_trx_processed) { build_stubbed(:cc_transaction, :processed, credit_card_biller: cc_biller) }

  # Inquiry
  let(:inquiry_url) { Channel::Pnl::Base::INQUIRY_URL }
  let(:inquiry_payload) {{ number: customer_number, bank: cc_biller.biller_code }}
  let(:success_inquiry_response) {{
    "message" => "Akun bank valid.",
    "data" => {"valid" => true, "name" => "JAMIL HAZAMI ULALALA"},
    "meta" => {"http_status" => 200}
  }}
  let(:failed_inquiry_response) {{
    "message"=>"Akun bank tidak valid.",
    "data"=>{"valid"=>false, "name"=>""},
    "meta"=>{"http_status"=>200}
  }}

  # Payment
  let(:payment_url) { Channel::Pnl::Base::PAY_URL }
  let(:mitra_payment_url) { Channel::Pnl::Base::MITRA_PAY_URL }
  let(:mitra_payment_path) { Channel::Pnl::Base::MITRA_PAY_PATH }
  let(:payment_payload) {{
    payments: [{
      id: cc_trx_paid.order_id,
      amount: cc_trx_paid.base_amount,
      txn_date: DateTime.now.strftime('%Y-%m-%d'),
      receiver: {
        account_no: cc_trx_paid.card_number,
        bank: cc_partner.biller_code,
        name: cc_trx_paid.customer_name,
      },
      reference_type: :olympus_transferdbs_ccbill,
      reference_id: cc_trx_paid.id
    }],
    callback_url: Channel::Pnl::Base::CALLBACK_URL,
  }}
  let(:mitra_payment_payload) do
    {
      id: cc_trx_paid.order_id,
      remote_type: CREDIT_CARD_BILL_PRODUCT,
      user: described_class::OLYMPUS_USER,
      transaction: {
        amount: cc_trx_paid.base_amount,
        beneficiary_bank_name: cc_trx_paid.biller.partner.biller_code,
        beneficiary_account_no: cc_trx_paid.card_number,
        beneficiary_name: cc_trx_paid.customer_name,
      }
    }
  end
  let(:success_payment_response) {{:message=>"Permintaan anda berhasil diproses", :meta=>{:http_status=>200}}}
  let(:failed_payment_response) {{
    errors: [{ message: "Permintaan saat ini tidak dapat diproses", code: 22100 }],
    meta: { http_status: 422 }
  }}

  # Confirm
  let(:confirm_url) { Channel::Pnl::Base::CONFIRM_URL }
  let(:confirm_payload) {{
    customer_reference: cc_trx_processed.order_id
  }}
  let(:success_confirm_response) {{
    data: {
      sender_party: {
        name: "BUKALAPAK.COM PT"
      },
      inquiry_status_code: "ACSP",
      customer_reference: "CC-1",
      transaction: {
        settlement_amount: 446000,
        rejected_code: "",
        status_code: "ACTC",
        reference_id: "R20201231231",
        amount: 446000,
        settlement_date: "2020-06-15 13:18:07.123",
        status_description: ""
      },
      receiving_party: {
        name: "GIORNO GIOVANNA",
        account_number: "2932d03d3ba04ae4a770240f3ba8bd34bce93ebd1d2549d69ad483df13e513f8",
        bank_name: "Bank Mega",
        bank_code: "426"
      }
    },
    meta: {
      http_status: 200
    }
  }}

  # HTTP
  let(:http_opts) {{ crypto_hash_object_keys: Channel::Pnl::Base::CC_NUMBER_KEY_NAMES }}

  before { allow(cc_biller).to receive(:partner).and_return(cc_partner) }

  describe '#can_confirm?' do
    subject { described_class.new.can_confirm? }
    it { is_expected.to eq true }
  end

  describe '#inquiry' do
    subject { described_class.new.inquiry(customer_number, biller_id) }

    before do
      allow(CreditCardBiller).to receive(:find_by).and_return(cc_biller)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status, :response_code
      )).and_return(true)
    end

    context 'when status is success' do
      it 'should not raise error' do
        expect(Channel::Connection::Http).to receive(:post).with(inquiry_url, auth, inquiry_payload, any_args, http_opts).and_return(success_inquiry_response.to_json)
        expect{ subject }.not_to raise_error
      end
    end

    context 'when status is failed' do
      it 'should raise corresponding error' do
        expect(Channel::Connection::Http).to receive(:post).with(inquiry_url, auth, inquiry_payload, any_args, http_opts).and_return(failed_inquiry_response.to_json)
        expect{ subject }.to raise_error(Exceptions::PostpaidError)
      end
    end

    context 'when error' do
      before do
        expect(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception.new)
      end
      it { expect { subject }.to raise_error(Exceptions::BtsKube::InquiryError) }
    end
  end

  describe 'REST-2693: #payment' do
    normal_credential_transaction_types = [:agent, :normal, :procurement]
    bmi_credential_transaction_types = [:collecting_agent]

    subject { described_class.new.create(cc_trx_paid) }

    normal_credential_transaction_types.each do |transaction_type|
      context 'when transaction is #{transaction_type}' do
        before do
          expect(Channel::Connection::Http).to receive(:post).with(payment_url, auth, payment_payload, any_args, http_opts).and_return(success_payment_response.to_json)
          expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
            :action, :partner, :product, :biller_product, :status, :response_code
          )).and_return(true)
        end

        [true, false].each do |value|
          context "when toggle pnl mitra auth active is #{value}" do
            before do
              expect(Toggles::PnlMitraAuth).to receive(:active?).and_return(value)
            end
            it('should not raise error') { expect{ subject }.not_to raise_error }
          end
        end
      end
    end

    bmi_credential_transaction_types.each do |transaction_type|
      context "when transaction is #{transaction_type}" do
        let(:cc_trx_paid) { build_stubbed(:cc_transaction, :paid, transaction_type, credit_card_biller: cc_biller) }

        before do
          expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
            :action, :partner, :product, :biller_product, :status, :response_code
          )).and_return(true)
        end

        context 'when toggle pnl mitra auth is active' do
          before do
            expect(Toggles::PnlMitraAuth).to receive(:active?).and_return(true)
            expect(Channel::Connection::Http).to receive(:post).with(mitra_payment_url, auth, mitra_payment_payload, any_args, http_opts).and_return(success_payment_response.to_json)
          end
          it('should not raise error') { expect{ subject }.not_to raise_error }

          context 'when preprod force to use non wiremock' do
            let(:forced_url) { 'http://bts-kube.preproduction.internal.' }
            let(:mitra_payment_url) { "#{forced_url}#{mitra_payment_path}" }
            before do
              expect(ENV).to receive(:[]).with('PREPROD_FORCE_PNL_NON_WIREMOCK').and_return('true')
              expect(ENV).to receive(:[]).with('BTS_KUBE_NON_WIREMOCK_URL').and_return(forced_url)
            end
            it('should not raise error') { expect{ subject }.not_to raise_error }
          end
        end

        context 'when toggle pnl mitra auth is inactive' do
          before do
            expect(Toggles::PnlMitraAuth).to receive(:active?).and_return(false)
            expect(Channel::Connection::Http).to receive(:post).with(payment_url, auth, payment_payload, any_args, http_opts).and_return(success_payment_response.to_json)
          end
          it('should not raise error') { expect{ subject }.not_to raise_error }
        end
      end
    end

    context 'when error in partner' do
      before do
        expect(Toggles::PnlMitraAuth).to receive(:active?).and_return(false)
        expect(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception.new)
      end
      it { expect { subject }.to raise_error(Exceptions::BtsKube::PaymentError) }
    end
  end

  describe '#confirm' do
    subject { described_class.new.confirm(cc_trx_processed) }

    context 'when status is success' do
      before do
        expect(Channel::Connection::Http).to receive(:post).with(confirm_url, auth, confirm_payload).and_return(success_confirm_response.to_json)
      end
      it { expect { subject }.not_to raise_error }
    end

    context 'when error' do
      before do
        expect(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception.new)
      end
      it { expect { subject }.to raise_error(Exceptions::BtsKube::ConfirmError) }
    end
  end
end
