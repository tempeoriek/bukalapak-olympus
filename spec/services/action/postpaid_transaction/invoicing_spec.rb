require "rails_helper"

RSpec.describe Action::PostpaidTransaction::Invoicing, type: :model do
  let(:transaction) { create(:postpaid_transaction_with_bill, :partner_sepulsa) }
  let(:invalid_invoice_id) { "test" }
  let(:valid_invoice_id) { 1 }

  context "transaction invoicing" do
    it "should raise error if invoice id is invalid" do
      action = Action::PostpaidTransaction::Invoicing.new(transaction, invalid_invoice_id)
      expect { action.run! }.to raise_error(Exceptions::CreateTransactionError)
    end

    it "should not raise error if invoice id is valid" do
      action = Action::PostpaidTransaction::Invoicing.new(transaction, valid_invoice_id)
      expect(transaction.invoice_id).to eq(valid_invoice_id)
      expect { action.run! }.not_to raise_error
    end
  end
end
