require 'rails_helper'
require 'support/rake'

describe "transaction:cleanup:all" do
  include_context "rake"
  include Postpaid::Constant

  context 'with paid stuck transaction' do
    let(:provider) { build_stubbed :phone_credit_provider }

    before do
      allow(GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, hash_including(product_type: ELECTRICITY_PRODUCT), anything).and_return(true)
      allow(GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, hash_including(product_type: BPJS_KESEHATAN_PRODUCT), anything).and_return(true)
      allow(GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, hash_including(product_type: PHONE_CREDIT_PRODUCT), anything).and_return(true)
      allow(GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, hash_including(product_type: PDAM_PRODUCT), anything).and_return(true)
      allow(PhoneCreditProvider).to receive(:find).and_return(provider)

      create(:bpjs_kesehatan_transaction, :paid, paid_at: 20.minute.ago)
      create(:pdam_transaction_with_bill, :paid, paid_at: 20.minute.ago)
      create(:phone_credit_postpaid_transaction, :paid, paid_at: 20.minute.ago)
      create(:postpaid_transaction_with_bill, :paid, paid_at: 20.minute.ago)

      create(:postpaid_transaction_with_bill, :paid)
      create(:phone_credit_postpaid_transaction, :paid)
      create(:pdam_transaction_with_bill, :paid)
      create(:bpjs_kesehatan_transaction, :paid)
    end

    it "process paid transaction which 15 minutes old" do
      subject.invoke
    end
  end

  context 'with processed stuck transaction' do
    let(:provider) { build_stubbed :phone_credit_provider }

    run_times = 0

    before do
      allow(PhoneCreditProvider).to receive(:find).and_return(provider)
      
      Action::PostpaidTransaction::Confirm.any_instance.stub(:run!) do |arg|
        run_times += 1
      end
      create(:bpjs_kesehatan_transaction, :processed, processed_at: 20.minute.ago)
      create(:pdam_transaction_with_bill, :processed, processed_at: 20.minute.ago)
      create(:phone_credit_postpaid_transaction, :processed, processed_at: 20.minute.ago)
      create(:postpaid_transaction_with_bill, :processed, processed_at: 20.minute.ago)

      create(:postpaid_transaction_with_bill, :processed)
      create(:phone_credit_postpaid_transaction, :processed)
      create(:pdam_transaction_with_bill, :processed)
      create(:bpjs_kesehatan_transaction, :processed)
    end

    it "confirm processed transaction which 15 minutes old" do
      subject.invoke
      expect(run_times).to eq(4)
    end
  end

  context 'with partner_succeeded stuck transaction' do
    let(:provider) { build_stubbed :phone_credit_provider }

    run_times = 0

    before do
      allow(PhoneCreditProvider).to receive(:find).and_return(provider)

      Action::PostpaidTransaction::UpdateRemote.any_instance.stub(:run!) do |arg|
        run_times += 1
      end
      create(:bpjs_kesehatan_transaction, :partner_succeeded, partner_succeeded_at: 20.minute.ago)
      create(:pdam_transaction_with_bill, :partner_succeeded, partner_succeeded_at: 20.minute.ago)
      create(:phone_credit_postpaid_transaction, :partner_succeeded, partner_succeeded_at: 20.minute.ago)
      create(:postpaid_transaction_with_bill, :partner_succeeded, partner_succeeded_at: 20.minute.ago)

      create(:postpaid_transaction_with_bill, :partner_succeeded)
      create(:phone_credit_postpaid_transaction, :partner_succeeded)
      create(:pdam_transaction_with_bill, :partner_succeeded)
      create(:bpjs_kesehatan_transaction, :partner_succeeded)
    end

    it "confirm partner_succeeded transaction which 15 minutes old" do
      subject.invoke
      expect(run_times).to eq(4)
    end
  end

  context 'with partner_failed stuck transaction' do
    let(:provider) { build_stubbed :phone_credit_provider }

    run_times = 0

    before do
      allow(PhoneCreditProvider).to receive(:find).and_return(provider)
      
      Action::PostpaidTransaction::UpdateRemote.any_instance.stub(:run!) do |arg|
        run_times += 1
      end
      create(:bpjs_kesehatan_transaction, :partner_failed, partner_failed_at: 20.minute.ago)
      create(:pdam_transaction_with_bill, :partner_failed, partner_failed_at: 20.minute.ago)
      create(:phone_credit_postpaid_transaction, :partner_failed, partner_failed_at: 20.minute.ago)
      create(:postpaid_transaction_with_bill, :partner_failed, partner_failed_at: 20.minute.ago)

      create(:postpaid_transaction_with_bill, :partner_failed)
      create(:phone_credit_postpaid_transaction, :partner_failed)
      create(:pdam_transaction_with_bill, :partner_failed)
      create(:bpjs_kesehatan_transaction, :partner_failed)
    end

    it "confirm partner_failed transaction which 15 minutes old" do
      subject.invoke
      expect(run_times).to eq(4)
    end
  end
end
