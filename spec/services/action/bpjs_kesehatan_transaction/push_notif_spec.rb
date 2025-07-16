require "rails_helper"

RSpec.describe Action::BpjsKesehatanTransaction::PushNotif, type: :model do
  include Postpaid::Constant
  let(:transaction) {build_stubbed(:bpjs_kesehatan_transaction)}

  before do
    allow(Channel::Connection::Http).to receive(:post).and_return true
  end

  context 'remitted' do
    it 'does not raise error' do
      expect{Action::BpjsKesehatanTransaction::PushNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REMIT).run!}.not_to raise_error
    end
  end

  context 'refunded' do
    it 'does not raise error' do
      expect{Action::BpjsKesehatanTransaction::PushNotif.new(transaction, Postpaid::Constant::BUKALAPAK_REFUND).run!}.not_to raise_error
    end
  end
end
