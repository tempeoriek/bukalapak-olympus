require 'rails_helper'
require 'json'

RSpec.describe Escrow::RegisterTransaction, type: :model do
  let(:transaction) { build_stubbed(:postpaid_transaction_with_bill) }

  context 'request' do
    let(:time_now) { Time.now }
    let(:response) do
      {
        data: {
          id: 1,
          state: "pending"
        },
        meta: {
          http_status:201
        }
      }
    end

    before do
      allow_any_instance_of(Escrow::RegisterTransaction).to receive(:parse_response).and_return(response)
    end

    it 'send correct payload' do
      object = Escrow::RegisterTransaction.new(transaction)
      expect(Escrow::Connection).to receive(:post).with(
        any_args,
        hash_including(
            remote_id: transaction.id,
            buyer_id: transaction.buyer_id,
            amount: transaction.amount,
            remote_type: transaction.product_type
        )
      )
      object.run!
    end
  end

  context 'response' do
    it 'parse result witout error' do
      # mock url with 'internal' path
      stub_request(:post, /internal/).to_return(
        body: {
          data: {
            id: 1,
            state: "pending"
          },
          meta: {
            http_status:201
          }
        }.to_json,
        status: 201
      )

      object = Escrow::RegisterTransaction.new(transaction)
      expect{object.run!}.not_to raise_error
    end
  end
end
