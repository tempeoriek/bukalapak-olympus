require 'rails_helper'

RSpec.describe Action::PostpaidTransaction::SendNotification, type: :model do
  let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :succeeded) }

  describe '.run!' do
    subject { Action::PostpaidTransaction::SendNotification.new(transaction) }
    it 'triggers email, push notif, and onsite notif' do
      expect(Toggles::EmailNotif).to receive(:active?).and_return true
      expect(Toggles::PushNotif).to receive(:active?).and_return true
      expect(Toggles::OnSiteNotif).to receive(:active?).and_return true
      expect(GcpsPublisher).to receive(:publish).and_return true
      expect_any_instance_of(Action::ElectricityTransaction::PushNotif).to receive(:run!).and_return true
      expect_any_instance_of(Action::ElectricityTransaction::OnsiteNotif).to receive(:run!).and_return true
      expect { subject.run! }.not_to raise_error
    end
  end
end
