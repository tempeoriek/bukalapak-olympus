require "rails_helper"

RSpec.describe Action::PhoneCreditTransaction::PushNotif, type: :model do
  include Postpaid::Constant
  let(:transaction) {build_stubbed(:phone_credit_postpaid_transaction)}
  let(:provider) { build_stubbed(:phone_credit_provider) }
  let(:telolet_url) { described_class::URL }

  before { allow(PhoneCreditProvider).to receive(:find).and_return(provider) }

  describe '#run!' do
    context 'when remitted' do
      context 'when transaction type is normal' do
        it 'does not raise error and produces correct output' do
          expect(Channel::Connection::Http).to receive(:post).with(anything, anything,
            hash_including(
              :source,
              :queue,
              :version,
              data: hash_including(:user_id, :headings, :contents, :url, :tag, :platform)
            )
          ).exactly(5).times.and_return true

          expect{Action::PhoneCreditTransaction::PushNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REMIT).run!}.not_to raise_error
        end
      end
    end

    context 'when refunded' do
      context 'when transaction type is normal' do
        it 'does not raise error and produces correct output' do
          expect(Channel::Connection::Http).to receive(:post).with(anything, anything,
            hash_including(
              :source,
              :queue,
              :version,
              data: hash_including(:user_id, :headings, :contents, :url, :tag, :platform)
            )
          ).exactly(5).times.and_return true

          expect{Action::PhoneCreditTransaction::PushNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REFUND).run!}.not_to raise_error
        end
      end
    end
  end
end
