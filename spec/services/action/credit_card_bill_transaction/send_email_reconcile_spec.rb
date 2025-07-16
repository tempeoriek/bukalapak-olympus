require "rails_helper"

RSpec.describe Action::CreditCardBillTransaction::SendEmailReconcile, type: :model do
  
  describe '#run!' do
    context 'when successfully sending email BNI reconcile' do
      before do
        allow(::Channel::Notif).to receive(:send_email).and_return(true)
      end

      let(:transaction) {build_stubbed(:cc_transaction, :succeeded)}
      let(:start_time){ transaction.processed_at.tomorrow.beginning_of_day }
      let(:end_time) { transaction.processed_at.tomorrow.beginning_of_day }
      let(:file_name) { "BUKALAPAK#{start_time.strftime('%Y%m%d')}.csv" }

      subject { Action::CreditCardBillTransaction::SendEmailReconcile.new(start_time, end_time, file_name) }

      it do
        response = subject.run!
        expect(response).to include(file_name)
        expect{ response }.not_to raise_error
      end
    end
  end
end