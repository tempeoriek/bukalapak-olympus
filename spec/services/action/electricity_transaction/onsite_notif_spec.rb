require "rails_helper"

RSpec.describe Action::ElectricityTransaction::OnsiteNotif, type: :model do
  include Postpaid::Constant

  before do
    allow(Channel::Connection::Http).to receive(:post).and_return true
  end

  describe '.run!' do
    let(:transaction) {build_stubbed(:postpaid_transaction_with_bill)}
    context 'when remitted' do
      it 'does not raise error' do
        expect{Action::ElectricityTransaction::OnsiteNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REMIT).run!}.not_to raise_error
      end
    end

    context 'when refunded' do
      it 'does not raise error' do
        expect{Action::ElectricityTransaction::OnsiteNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REFUND).run!}.not_to raise_error
      end
    end

    let(:recurrent_transaction) {build_stubbed(:postpaid_transaction_with_bill, :recurrent)}
    context 'when remitted recurrent' do
      it 'does not raise error' do
        expect{Action::ElectricityTransaction::OnsiteNotif.new(recurrent_transaction, Postpaid::Constant::BUKALAPAK_REMIT).run!}.not_to raise_error
      end
    end

    context 'when refunded recurrent' do
      it 'does not raise error' do
        expect{Action::ElectricityTransaction::OnsiteNotif.new(recurrent_transaction, Postpaid::Constant::BUKALAPAK_REFUND).run!}.not_to raise_error
      end
    end
  end
end
