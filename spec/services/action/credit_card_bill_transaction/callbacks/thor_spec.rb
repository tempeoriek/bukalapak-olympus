require "rails_helper"

RSpec.describe Action::CreditCardBillTransaction::Callbacks::Thor, type: :model do

  let(:transaction) { create(:cc_transaction, :processed) }

  describe '#run!' do
    before do
      allow_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
      allow_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
      allow(Toggles::OlympusSievexSend).to receive(:active?).and_return false
      transaction
    end

    context 'with valid params' do
      let(:params) { ActionController::Parameters.new({
        "credit_card_bill_transaction": {
          "order_id": "CC-1",
          "card_number": "5200000068",
          "account_number": "123456",
          "customer_name": "John Doe",
          "statement_date": "2023-01-01",
          "due_date": "2023-02-01",
          "minimum_payment": "50000",
          "admin_charge": "1000",
          "amount": "234000",
          "reference_number": "G001T00100000001",
          "financial_journal_number": "24325513",
          "journal_number": "56632111",
          "info": "info",
          "response_code": "0000",
          "message": "successful"
        }
      }) }

      subject { described_class.new(params) }

      before do
        expect_any_instance_of(described_class).to receive(
          :cache_partner_response
        ).with(
          transaction.product_type,
          'callback',
          transaction.partner_name,
          transaction.remote_transaction_id,
          'success'
        ).and_return(true)
      end

      it 'does not raise error' do
        expect { subject.run! }.not_to raise_error
        transaction.reload # get the latest value
        expect( transaction.customer_name ).to eq('John Doe')
        expect( transaction.statement_date ).to eq(Date.new(2023, 1, 1))
        expect( transaction.due_date ).to eq(Date.new(2023, 2, 1))
        expect( transaction.minimum_payment ).to eq(50000)
        expect( transaction.partner_financial_journal_number ).to eq('24325513')
        expect( transaction.reference_number ).to eq('G001T00100000001')
        expect( transaction.state ).to eq('partner_succeeded')
      end
    end

    context 'with no status' do
      let(:params) { ActionController::Parameters.new({
        "credit_card_bill_transaction": {
          "order_id": "CC-1",
          "card_number": "5200000068",
          "account_number": "123456",
          "customer_name": "John Doe",
          "statement_date": "2023-01-01",
          "due_date": "2023-02-01",
          "minimum_payment": "50000",
          "admin_charge": "1000",
          "amount": "234000",
          "reference_number": "G001T00100000001",
          "financial_journal_number": "24325513",
          "journal_number": "56632111",
          "info": "info",
          "response_code": "",
          "message": ""
        }
      }) }

      subject { described_class.new(params) }

      before do
        expect_any_instance_of(described_class).to receive(
          :cache_partner_response
        ).with(
          transaction.product_type,
          'callback',
          transaction.partner_name,
          transaction.remote_transaction_id,
          'error'
        ).and_return(true)
      end

      it 'does raise error' do
        expect { subject.run! }.to raise_error(::Exceptions::InvalidStatusError)
        transaction.reload # get the latest value
        expect( transaction.reference_number ).to eq('G001T00100000001')
        expect( transaction.state ).to eq('processed')
      end
    end
  end
end
