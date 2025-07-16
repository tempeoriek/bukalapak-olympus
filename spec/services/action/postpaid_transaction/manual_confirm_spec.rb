require "rails_helper"

RSpec.describe Action::PostpaidTransaction::ManualConfirm, type: :model do
  subject { Action::PostpaidTransaction::ManualConfirm }

  context "electricity postpaid" do
    context "when processed" do
      let(:electricity_transaction_processed) { build(:postpaid_transaction_with_bill, :processed, processed_at: Time.now - 4.hours) }
      let(:electricity_subject) { subject.new(electricity_transaction_processed) }

      # it "raise error and do not process if partner transaction not found" do
      #   allow_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!).and_raise(Exceptions::PartnerTransactionNotFound)
      #   expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).never
      #   expect_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).never
      #   expect { electricity_subject.run! }.to raise_error(Exceptions::PartnerTransactionNotFound)
      # end
      context 'when partner not found' do
        context 'when it is eligible for refund' do
          before { allow(Toggle::AutoRefundConfirmTransactionNotFound).to receive(:active?).and_return(true) }

          it 'refunds transaction' do
            allow_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!).and_raise(Exceptions::PartnerTransactionNotFound)
            allow(electricity_transaction_processed).to receive_message_chain(:partner_object, :name).and_return('ayoconnect')
            expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!)
            expect_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!)
            expect { electricity_subject.run! }.to raise_error(Exceptions::PartnerTransactionNotFound)
          end
        end

        context 'when it is not eligible for refund' do
          before { allow(Toggle::AutoRefundConfirmTransactionNotFound).to receive(:active?).and_return(false) }

          it 'does not refund' do
            allow_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!).and_raise(Exceptions::PartnerTransactionNotFound)
            allow(electricity_transaction_processed).to receive_message_chain(:partner_object, :name).and_return('invalid_partner')
            expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).never
            expect_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).never
            expect { electricity_subject.run! }.to raise_error(Exceptions::PartnerTransactionNotFound)
          end
        end
      end
    end

    context "when succeeded" do
      let(:electricity_transaction_succeeded) { build(:postpaid_transaction_with_bill, :succeeded) }
      let(:electricity_subject) { subject.new(electricity_transaction_succeeded) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { electricity_subject.run! }.not_to raise_error
      end
    end

    context "when failed" do
      let(:electricity_transaction_failed) { build(:postpaid_transaction_with_bill, :failed) }
      let(:electricity_subject) { subject.new(electricity_transaction_failed) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { electricity_subject.run! }.not_to raise_error
      end
    end

    context "when partner_succeeded" do
      let(:electricity_transaction_partner_succeeded) { build(:postpaid_transaction_with_bill, :partner_succeeded) }
      let(:electricity_subject) { subject.new(electricity_transaction_partner_succeeded) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { electricity_subject.run! }.not_to raise_error
      end
    end

    context "when partner_failed" do
      let(:electricity_transaction_partner_failed) { build(:postpaid_transaction_with_bill, :partner_failed) }
      let(:electricity_subject) { subject.new(electricity_transaction_partner_failed) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { electricity_subject.run! }.not_to raise_error
      end
    end

    context 'when wrong state' do
      let(:electricity_transaction_partner_pending) { build(:postpaid_transaction_with_bill) }
      let(:electricity_subject) { subject.new(electricity_transaction_partner_pending) }

      it {
        expect { electricity_subject.run! }.to raise_error(Exceptions::CannotManualConfirmTransaction)
      }
    end
  end

  context "bpjs kesehatan" do
    context "when processed" do
      let(:bpjs_kesehatan_processed) { build(:bpjs_kesehatan_transaction, :processed) }
      let(:bpjs_kesehatan_subject) { subject.new(bpjs_kesehatan_processed) }

      it "raise error and do not process if partner transaction not found" do
        allow_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!).and_raise(Exceptions::PartnerTransactionNotFound)
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).never
        expect_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).never
        expect { bpjs_kesehatan_subject.run! }.to raise_error(Exceptions::PartnerTransactionNotFound)
      end
    end

    context "when succeeded" do
      let(:bpjs_kesehatan_succeeded) { build(:bpjs_kesehatan_transaction, :succeeded) }
      let(:bpjs_kesehatan_subject) { subject.new(bpjs_kesehatan_succeeded) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { bpjs_kesehatan_subject.run! }.not_to raise_error
      end
    end

    context "when failed" do
      let(:bpjs_kesehatan_failed) { build(:bpjs_kesehatan_transaction, :failed) }
      let(:bpjs_kesehatan_subject) { subject.new(bpjs_kesehatan_failed) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { bpjs_kesehatan_subject.run! }.not_to raise_error
      end
    end

    context "when partner_succeeded" do
      let(:bpjs_kesehatan_partner_succeeded) { build(:bpjs_kesehatan_transaction, :partner_succeeded) }
      let(:bpjs_kesehatan_subject) { subject.new(bpjs_kesehatan_partner_succeeded) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { bpjs_kesehatan_subject.run! }.not_to raise_error
      end
    end

    context "when partner_failed" do
      let(:bpjs_kesehatan_partner_failed) { build(:bpjs_kesehatan_transaction, :partner_failed) }
      let(:bpjs_kesehatan_subject) { subject.new(bpjs_kesehatan_partner_failed) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { bpjs_kesehatan_subject.run! }.not_to raise_error
      end
    end

    context 'when wrong state' do
      let(:bpjs_kesehatan_partner_pending) { build(:bpjs_kesehatan_transaction) }
      let(:bpjs_kesehatan_subject) { subject.new(bpjs_kesehatan_partner_pending) }

      it {
        expect { bpjs_kesehatan_subject.run! }.to raise_error(Exceptions::CannotManualConfirmTransaction)
      }
    end
  end

  context "pdam" do
    context "when processed" do

      context 'when toggle auto refund is inactive' do
        let(:pdam_processed) { build(:pdam_transaction_with_bill, :processed) }
        let(:pdam_subject) { subject.new(pdam_processed) }
        it "raise error and do not process if partner transaction not found" do
          allow_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!).and_raise(Exceptions::PartnerTransactionNotFound)
          expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).never
          expect_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).never
          expect { pdam_subject.run! }.to raise_error(Exceptions::PartnerTransactionNotFound)
        end
      end

      context 'when toggle auto refund is active' do
        before { allow(Toggle::AutoRefundConfirmTransactionNotFound).to receive(:active?).and_return(true) }

        context 'when the transaction processed date is within 3 hours' do
          let(:pdam_processed) { build(:pdam_transaction_with_bill, :processed) }
          let(:pdam_subject) { subject.new(pdam_processed) }
          it "raise error partner transaction not found but do not trigger auto refund and update remote fail" do
            allow_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!).and_raise(Exceptions::PartnerTransactionNotFound)
            allow(pdam_subject).to receive(:eligible_autorefund?).and_return false
            expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).not_to receive(:run!).once
            expect_any_instance_of(Action::PostpaidTransaction::SendNotification).not_to receive(:run!).once
            expect { pdam_subject.run! }.to raise_error(Exceptions::PartnerTransactionNotFound)
          end
        end

        context 'when the transaction processed date is 3 hours ago or earlier' do
          let(:pdam_processed_three_hours_ago) { build(:pdam_transaction_with_bill, :processed_three_hours_ago) }
          let(:pdam_subject_three_hours_ago) { subject.new(pdam_processed_three_hours_ago) }
          it "raise error partner transaction not found and do trigger auto refund and update remote fail" do
            allow_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!).and_raise(Exceptions::PartnerTransactionNotFound)
            allow(pdam_subject_three_hours_ago).to receive(:eligible_autorefund?).and_return true
            expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).once
            expect_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).once
            expect { pdam_subject_three_hours_ago.run! }.to raise_error(Exceptions::PartnerTransactionNotFound)
          end
        end
      end
    end

    context "when succeeded" do
      let(:pdam_succeeded) { build(:pdam_transaction_with_bill, :succeeded) }
      let(:pdam_subject) { subject.new(pdam_succeeded) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { pdam_subject.run! }.not_to raise_error
      end
    end

    context "when failed" do
      let(:pdam_failed) { build(:pdam_transaction_with_bill, :failed) }
      let(:pdam_subject) { subject.new(pdam_failed) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { pdam_subject.run! }.not_to raise_error
      end
    end

    context "when partner_succeeded" do
      let(:pdam_partner_succeeded) { build(:pdam_transaction_with_bill, :partner_succeeded) }
      let(:pdam_subject) { subject.new(pdam_partner_succeeded) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { pdam_subject.run! }.not_to raise_error
      end
    end

    context "when partner_failed" do
      let(:pdam_partner_failed) { build(:pdam_transaction_with_bill, :partner_failed) }
      let(:pdam_subject) { subject.new(pdam_partner_failed) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { pdam_subject.run! }.not_to raise_error
      end
    end

    context 'when wrong state' do
      let(:pdam_partner_pending) { build(:pdam_transaction_with_bill) }
      let(:pdam_subject) { subject.new(pdam_partner_pending) }

      it {
        expect { pdam_subject.run! }.to raise_error(Exceptions::CannotManualConfirmTransaction)
      }
    end
  end

  context "phone_credit_postpaid" do
    let(:provider) { build_stubbed(:phone_credit_provider) }

    before do
      allow(PhoneCreditProvider).to receive(:find).and_return(provider)
    end

    context "when processed" do
      let(:phone_credit_trx) { build(:phone_credit_postpaid_transaction, :processed) }
      let(:curr_subject) { subject.new(phone_credit_trx) }

      it "raise error and do not process if partner transaction not found" do
        allow_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!).and_raise(Exceptions::PartnerTransactionNotFound)
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).never
        expect_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).never
        expect { curr_subject.run! }.to raise_error(Exceptions::PartnerTransactionNotFound)
      end
    end

    context "when succeeded" do
      let(:phone_credit_trx) { build(:phone_credit_postpaid_transaction, :succeeded) }
      let(:curr_subject) { subject.new(phone_credit_trx) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { curr_subject.run! }.not_to raise_error
      end
    end

    context "when failed" do
      let(:phone_credit_trx) { build(:phone_credit_postpaid_transaction, :failed) }
      let(:curr_subject) { subject.new(phone_credit_trx) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { curr_subject.run! }.not_to raise_error
      end
    end

    context "when partner_succeeded" do
      let(:phone_credit_trx) { build(:phone_credit_postpaid_transaction, :partner_succeeded) }
      let(:curr_subject) { subject.new(phone_credit_trx) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { curr_subject.run! }.not_to raise_error
      end
    end

    context "when partner_failed" do
      let(:phone_credit_trx) { build(:phone_credit_postpaid_transaction, :partner_failed) }
      let(:curr_subject) { subject.new(phone_credit_trx) }

      it "trigger update remote transaction status" do
        expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
        expect { curr_subject.run! }.not_to raise_error
      end
    end

    context 'when wrong state' do
      let(:phone_credit_trx) { build(:phone_credit_postpaid_transaction) }
      let(:curr_subject) { subject.new(phone_credit_trx) }

      it {
        expect { curr_subject.run! }.to raise_error(Exceptions::CannotManualConfirmTransaction)
      }
    end
  end
end
