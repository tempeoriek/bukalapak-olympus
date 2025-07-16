require "rails_helper"
include PostpaidTransactionUtility

RSpec.describe Channel::BNI::Base, :credit_card_bill, type: :model do
  let(:token_key) { "bni_access_token" }
  let(:old_token) { "======= Cached Token ========" }
  let(:new_token) { "===== Access Token Baru =====" }
  let(:token_request_response) {
    {
      access_token: new_token,
      expires_in: 3600
    }.to_json
  }

  context 'when get_token called' do
    subject { Channel::BNI::Base.new.get_token }

    it 'return stored token' do
      expect(Keystore).to receive(:get).with(token_key).and_return(old_token)

      is_expected.to eq old_token
    end

    context 'with nil token' do
      it 'return stored token' do
        expect(Keystore).to receive(:get).with(token_key).and_return(nil)
        expect(Channel::Connection::Http).to receive(:post).and_return token_request_response
        res = JSON.parse(token_request_response).with_indifferent_access
        expect(Keystore).to receive(:set).with(token_key, res[:access_token], res[:expires_in]).and_return(true)

        is_expected.to eq new_token
      end
    end
  end
end
