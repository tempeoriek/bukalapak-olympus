require "rails_helper"

RSpec.describe Action::PostpaidTransaction::UpdateRemote, type: :model do
  let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :succeeded) }
  subject { Action::PostpaidTransaction::UpdateRemote.new(transaction) }

  describe "update remote transaction status" do
    context "when ran" do
      it "does not raise error and call publisher" do
        expect(::GcpsPublisher).to receive(:publish).and_return true
        expect { subject.run! }.not_to raise_error
      end
    end

    context "when failed" do
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :failed) }
      it "does not raise error and call publisher" do
        expect(::GcpsPublisher).to receive(:publish).and_return true
        expect { subject.run! }.not_to raise_error
      end
    end
  end
end