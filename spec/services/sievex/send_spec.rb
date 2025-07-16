require 'rails_helper'
require 'json'

RSpec.describe Sievex::Send, type: :model do
  let(:transaction) { build_stubbed(:cc_transaction, :paid_visa) }
  let(:state) { :processed }
  let(:sievex_response) { {} }
  let(:event_type) { described_class::EVENT_TYPE_MAP[state] }
  let(:entity_type) { described_class::ENTITY_TYPE_MAP[transaction.class] }
  let(:mock_time) { Time.new(2017, 5) }
  let(:encrypted_customer_number) { '1234ABC' }
  let(:payload) do
    {
      entity_type: entity_type,
      event_time:  mock_time.to_i,
      credit_card_bill_transaction: {
        transaction_id:   transaction.remote_transaction_id.to_s,
        transaction_type: transaction.transaction_type,
        state:            state,
        amount:           transaction.amount,
        customer_number:  encrypted_customer_number,
        created_at:       transaction.created_at.to_i,
        paid_at:          transaction.paid_at.to_i,
        buyer: {
          account_id:       transaction.buyer_id.to_s,
          account_type:     described_class::USER
        }
      }
    }
  end

  describe 'run!' do
    subject { described_class.new(transaction, state).run! }
    
    context 'when succeeded' do
      before do
        allow(Time).to receive(:now).and_return(mock_time)
        expect(transaction).to receive(:card_number).and_return(encrypted_customer_number)
        expect(::CreditCardBillHelper)
          .to receive(:crypto_hash_cc_number)
          .with(encrypted_customer_number)
          .and_return(encrypted_customer_number)
        expect(SieveX::Client).to receive(:track).with(event_type, payload).and_return(sievex_response)
      end

      it { expect{subject}.not_to raise_error }
      it { expect(subject).to eq(sievex_response) }
    end

    context 'when sievex raises error' do
      before do
        allow(Time).to receive(:now).and_return(mock_time)
        expect(transaction).to receive(:card_number).and_return(encrypted_customer_number)
        expect(::CreditCardBillHelper)
          .to receive(:crypto_hash_cc_number)
          .with(encrypted_customer_number)
          .and_return(encrypted_customer_number)
        expect(SieveX::Client).to receive(:track).with(event_type, payload).and_raise(StandardError)
      end

      it { expect{subject}.not_to raise_error }
      it { expect(subject).to eq(500) }
    end
  end
end
