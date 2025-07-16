require "rails_helper"

RSpec.describe Action::CreditCardBillTransaction::PnlCallback, type: :model do

  let(:transaction) { create(:cc_transaction, :processed) }

  describe '#run!' do
    before do
      allow_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
      allow_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
      allow(Toggles::OlympusSievexSend).to receive(:active?).and_return false
      transaction
    end

    context 'with ACTC params' do
      let(:params) { ActionController::Parameters.new({
        "payment_id": "CC-1",
        "reference_id": "G001T00100000001",
        "status": {
          "status": "ACTC",
          "code": "ACTC",
          "description": "SUCCESS",
          "reason": "SUCCESS"
        },
        "bank": "BRI",
        "payment_type": "bersama"
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
          'ACTC'
        ).and_return(true)
      end

      it 'does not raise error' do
        expect { subject.run! }.not_to raise_error
        transaction.reload # get the latest value
        expect( transaction.reference_number ).to eq('G001T00100000001')
        expect( transaction.state ).to eq('partner_succeeded')
      end
    end

    context 'with RJCT params' do
      let(:params) { ActionController::Parameters.new({
        "payment_id": "CC-1",
        "reference_id": "G001T00100000001",
        "status": {
          "status": "RJCT",
          "code": "RJCT",
          "description": "(04) Do Not Honor",
          "reason": "(04) Do Not Honor"
        },
        "bank": "BRI",
        "payment_type": "bersama"
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
          'RJCT'
        ).and_return(true)
      end

      it 'does raise error' do
        expect { subject.run! }.to raise_error(::Exceptions::InvalidStatusError)
        transaction.reload # get the latest value
        expect( transaction.reference_number ).to eq('G001T00100000001')
        expect( transaction.state ).to eq('processed')
      end
    end

    context 'with no status' do
      let(:params) { ActionController::Parameters.new({
        "payment_id": "CC-1",
        "reference_id": "G001T00100000001",
        "status": {
          "status": nil,
          "code": nil,
          "description": "unknown status",
          "reason": "unknown status"
        },
        "bank": "BRI",
        "payment_type": "bersama"
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
          'unknown_response'
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
