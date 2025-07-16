require 'rails_helper'
require 'support/pubsub_mocks'

describe Subscribers::PartnerProcessCcb do
  include_context 'pubsub_mocks'

  let(:transaction) { build_stubbed(:cc_transaction) }
  let(:message) {
    {
      remote_id: transaction.remote_transaction_id,
      product_type: transaction.product_type
    }.to_json
  }

  it 'not raise_error' do
    expect(CreditCardBillTransaction).to receive(:find_by_remote_transaction_id).and_return(transaction)
    expect_any_instance_of(Action::CreditCardBillTransaction::PartnerCreate).to receive(:run!)

    expect{ described_class.run }.not_to raise_error
  end
end
