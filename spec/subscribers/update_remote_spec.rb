require 'rails_helper'
require 'support/pubsub_mocks'

describe Subscribers::UpdateRemote do
  include_context 'pubsub_mocks'

  let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :partner_failed) }
  let(:message) {
    {
      remote_id: transaction.remote_transaction_id,
      product_type: transaction.product_type
    }.to_json
  }

  context 'when collecting agent transaction' do
    let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :collecting_agent, :partner_failed) }

    it 'send callback to middleman' do
      expect(PostpaidTransaction).to receive(:find_by_remote_transaction_id).and_return(transaction)
      expect_any_instance_of(Channel::Middleman::Callback).to receive(:run!)
      expect_any_instance_of(Escrow::UpdateTransactionStatus).to receive(:run!)

      expect{ described_class.run }.not_to raise_error
    end
  end

  context 'when non collecting agent transaction' do
    let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :partner_failed) }

    it 'send callback to middleman' do
      expect(PostpaidTransaction).to receive(:find_by_remote_transaction_id).and_return(transaction)
      expect_any_instance_of(Channel::Middleman::Callback).not_to receive(:run!)
      expect_any_instance_of(Escrow::UpdateTransactionStatus).to receive(:run!)

      expect{ described_class.run }.not_to raise_error
    end
  end

  context 'when product yet to join middleman' do
    let(:transaction) { build_stubbed(:pdam_transaction_with_bill, :partner_failed) }

    it 'send callback to middleman' do
      expect(PdamTransaction).to receive(:find_by_remote_transaction_id).and_return(transaction)
      expect_any_instance_of(Channel::Middleman::Callback).not_to receive(:run!)
      expect_any_instance_of(Escrow::UpdateTransactionStatus).to receive(:run!)

      expect{ described_class.run }.not_to raise_error
    end
  end
end
