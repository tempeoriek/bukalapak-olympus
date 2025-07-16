require "rails_helper"

RSpec.describe Action::PhoneCreditTransaction::OnsiteNotif, type: :model do
  include Postpaid::Constant
  let(:transaction) {build_stubbed(:phone_credit_postpaid_transaction)}
  let(:provider) { build_stubbed(:phone_credit_provider) }

  before { allow(PhoneCreditProvider).to receive(:find).and_return(provider) }

  describe '#run!' do
    context 'when remitted' do
      context 'when transaction type is normal' do
        it 'does not raise error and produces correct payload' do
          expect(Channel::Connection::Http).to receive(:post).with(anything, anything,
            hash_including(
              :user_id,
              :source,
              :queue,
              :version,
              :onsite_platform,
              body: hash_including(:title, :body, :image, :url, :tag)
            )
          ).twice.and_return true
          expect{Action::PhoneCreditTransaction::OnsiteNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REMIT).run!}.not_to raise_error
        end
      end
    end

    context 'when refunded' do
      context 'when transaction type is normal' do
        it 'does not raise error and produces correct payload' do
          expect(Channel::Connection::Http).to receive(:post).with(anything, anything,
            hash_including(
              :user_id,
              :source,
              :queue,
              :version,
              :onsite_platform,
              body: hash_including(:title, :body, :image, :url, :tag)
            )
          ).twice.and_return true
          expect{Action::PhoneCreditTransaction::OnsiteNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REFUND).run!}.not_to raise_error
        end
      end
    end
  end
end
