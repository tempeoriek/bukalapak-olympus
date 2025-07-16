require "rails_helper"

RSpec.describe Action::CreditCardBillTransaction::DeleteToken, type: :model do
  subject { described_class.new(transaction) }

  let(:transaction) {
    create(:cc_transaction, :paid_visa, credit_card_biller_id: biller.id, credit_card_bill_partner_id: biller.partner.id)
  }

  describe '#run!' do
    context 'when partner is visa' do
      let(:biller) { create(:credit_card_biller, :visa, :partner_visa) }
      it 'token will be deleted' do
        expect_any_instance_of(Channel::Visa::CreditCardBill).to receive(:delete_token).and_return true
        subject.run!
        expect(transaction.token).to be_nil
      end
    end
    context 'when partner is not visa' do
      let(:biller) { create(:credit_card_biller, :bni, :partner_bni) }
      it 'token will not be deleted' do
        expect_any_instance_of(Channel::Visa::CreditCardBill).not_to receive(:delete_token)
        subject.run!
        expect(transaction.token).not_to be_nil
      end
    end
  end

end
