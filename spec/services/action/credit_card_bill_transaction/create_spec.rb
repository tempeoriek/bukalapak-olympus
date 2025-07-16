require "rails_helper"

RSpec.describe Action::CreditCardBillTransaction::Create, type: :model do
  let(:buyer_id) { 1 }
  let(:customer_number) { '4111111111111111' }
  let(:form) {
    Form::CreditCardBill.new(customer_number, biller.id, 500000, username: 'sliu')
  }
  let(:escrow_response) { { id: 1 } }
  before {
    allow(Toggles::OlympusSievexSend).to receive(:active?).and_return false
    allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return escrow_response
    allow(Toggles::WhitelistVisa).to receive(:active?) { false }
    allow(Toggles::WhitelistBni).to receive(:active?) { false }
  }

  describe '#run!' do
    subject { described_class.new(form, buyer_id, 0) }

    context 'when partner is visa' do
      let(:biller) { create(:credit_card_biller, :visa, :partner_visa) }
      let(:token_receipt_accept) {
        File.read('spec/fixtures/visa/cyber_source/token_receipt_accept.html')
      }
      it 'token is present and card_data is blank' do
        allow(Channel::Connection::Http).to receive(:post).and_return(token_receipt_accept)
        trx = subject.run!
        expect(trx.token).not_to be_blank
        expect(trx.card_data).to be_blank
      end
    end

    context 'when partner has no inquiry' do
      let(:biller) { create(:credit_card_biller, :partner_cimbniaga_thor) }

      it 'does not errors' do
        expect(Channel::Connection::Http).not_to receive(:post)
        trx = subject.run!
        expect(trx.customer_name).to be_blank
        expect(trx.statement_date).to be_blank
        expect(trx.card_data).to be_blank
      end
    end

    context 'when partner is non visa' do
      let(:biller) { create(:credit_card_biller, :non_bni, :partner_pnl) }
      let(:response) {
        {
          "message" => "Akun bank valid.",
          "data" => {"valid" => true, "name" => "JAMIL HAZAMI ULALALA"},
          "meta" => {"http_status" => 200}
        }.to_json
      }
      it 'both token and card_data are present' do
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
        trx = subject.run!
        expect(trx.token).not_to be_blank
        expect(trx.card_data).not_to be_blank
      end
    end
  end

end
