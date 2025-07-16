require "rails_helper"

RSpec.describe Action::PdamTransaction::OnsiteNotif, type: :model do
  include Postpaid::Constant
  let(:transaction) {build_stubbed(:pdam_transaction_with_bill)}

  before do
    allow(Channel::Connection::Http).to receive(:post).and_return true
  end

  context 'remitted' do
    it 'does not raise error' do
      expect{Action::PdamTransaction::OnsiteNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REMIT).run!}.not_to raise_error
    end
  end

  context 'refunded' do
    it 'does not raise error' do
      expect{Action::PdamTransaction::OnsiteNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REFUND).run!}.not_to raise_error
    end
  end
end
