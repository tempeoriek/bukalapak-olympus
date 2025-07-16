require "rails_helper"

RSpec.describe Action::PostpaidTransaction::PartnerCreate, type: :model do
  let(:pdam_channel) { Channel::Sepulsa::Pdam.new(pdam_transaction) }
  let(:electricity_channel) { Channel::Sepulsa::ElectricityPostpaid.new(electricity_transaction) }
  let(:electricity_channel_ayoconnect) { Channel::Ayoconnect::ElectricityPostpaid.new(electricity_transaction) }
  let(:bpjs_kesehatan_channel) { Channel::Sepulsa::BpjsKesehatan.new(bpjs_kesehatan_transaction) }
  let(:pdam_transaction) { create(:pdam_transaction_with_bill, :paid) }
  let(:electricity_transaction) { create(:postpaid_transaction_with_bill, :paid, :partner_sepulsa) }
  let(:bpjs_kesehatan_transaction) { create(:bpjs_kesehatan_transaction, :paid) }
  let(:electricity_partner) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  let(:electricity_partner_ayoconnect) { build_stubbed(:electricity_postpaid_partner, :ayoconnect) }
  let(:remote_transaction_id) { 1 }
  let(:response_channel_sepulsa) {
    {
      partner_transaction_id: "29048",
      status: 0 # status pending
    }
  }

  let(:electricity_generalizer) {
    r = ResponseGeneralizer::ElectricityPostpaid.new(response_channel_sepulsa, electricity_partner)
    r.status = 0
    r.partner_transaction_id = '29048'
    r
  }

  let(:pdam_generalizer) {
    r = ResponseGeneralizer::Pdam.new
    r.partner_transaction_id = '29048'
    r.status = 0
    r
  }

  let(:bpjs_kesehatan_generalizer) {
    r = ResponseGeneralizer::BpjsKesehatan.new
    r.partner_transaction_id = '29048'
    r.status = 0
    r
  }

  subject { Action::PostpaidTransaction::PartnerCreate }
  let(:electricity_subject) { subject.new(electricity_transaction) }
  let(:bpjs_kesehatan_subject) { subject.new(bpjs_kesehatan_transaction) }
  let(:pdam_subject) { subject.new(pdam_transaction) }

  context "electricity" do
    context "when calling PartnerCreate" do
      before(:each) do
        electricity_transaction.remote_transaction_id = remote_transaction_id
        allow(electricity_subject).to receive(:partner_channel).and_return(electricity_channel)
      end

      it "should raise error if transaction state is not paid" do
        allow(electricity_transaction).to receive(:paid?).and_return(false)
        expect { electricity_subject.run! }.to raise_error(Exceptions::TransactionNotPaid)
      end

      it "should not raise error and spawn job confirm if transaction state is paid" do
        allow(electricity_subject).to receive(:check_transaction).and_return(nil)
        allow(electricity_channel).to receive(:create_transaction).and_return(electricity_generalizer)
        expect(electricity_subject).to receive(:partner_confirm_transaction_job)
        expect { electricity_subject.run! }.not_to raise_error
      end
    end

    context 'when state not paid' do
      let(:electricity_transaction) { create(:postpaid_transaction_with_bill, :processed, :partner_sepulsa) }
      it 'raise error when state processed' do
        expect{ electricity_subject.run! }.to raise_error(Exceptions::TransactionNotPaid)
      end
    end

    context "check transaction" do
      before(:each) do
        allow(electricity_subject).to receive(:partner_channel).and_return(electricity_channel)
      end

      it "should return true and nil if options without check is true" do
        action = Action::PostpaidTransaction::PartnerCreate.new(electricity_transaction, without_check: true)
        expect(action.send(:check_transaction)).to eq(nil)
      end

      it "should return true and nil if result confirm_transaction is nil" do
        allow(electricity_channel).to receive(:confirm_transaction).and_raise(Exceptions::PartnerTransactionNotFound)
        expect(electricity_subject.send(:check_transaction)).to eq(nil)
      end

      it "should return false and response if result confirm_transaction is response" do
        allow(electricity_channel).to receive(:confirm_transaction).and_return(response_channel_sepulsa)
        expect(electricity_subject.send(:check_transaction)).to eq(response_channel_sepulsa)
      end
    end

    context "partner is ayoconnect" do
      let(:electricity_transaction) { create(:postpaid_transaction_with_bill, :paid, :partner_ayoconnect, :without_partner_transction_id) }

      before(:each) do
        allow(electricity_subject).to receive(:partner_channel).and_return(electricity_channel_ayoconnect)
        allow(electricity_subject).to receive(:check_transaction).and_return(nil)
        allow(electricity_channel_ayoconnect).to receive(:create_transaction).and_return(electricity_generalizer)
      end

      it 'should publish job with fixed delay' do
        publish_job_payload = {
          remote_id: electricity_transaction.remote_transaction_id,
          product_type: electricity_transaction.product_type,
          delay: described_class::AYOCONNECT_JOB_DELAY_SECONDS,
          fixed_delay: true
        }
        expect(GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_CONFIRM, publish_job_payload, track_id: publish_job_payload[:remote_id]).once
        expect { electricity_subject.run! }.not_to raise_error
      end

      it 'should change the partner transaction id' do 
        expect { electricity_subject.run! }.to change(electricity_transaction, :partner_transaction_id).from(nil).to(electricity_generalizer.partner_transaction_id)
      end
    end
  end

  context "bpjs kesehatan" do
    context "transaction" do
      before(:each) do
        bpjs_kesehatan_transaction.remote_transaction_id = remote_transaction_id
        allow(bpjs_kesehatan_subject).to receive(:partner_channel).and_return(bpjs_kesehatan_channel)
      end

      it "should raise error if transaction state is not paid" do
        allow(bpjs_kesehatan_transaction).to receive(:paid?).and_return(false)
        expect { bpjs_kesehatan_subject.run! }.to raise_error(Exceptions::TransactionNotPaid)
      end

      it "should not raise error and spawn job confirm if transaction state is paid" do
        allow(bpjs_kesehatan_subject).to receive(:check_transaction).and_return(nil)
        allow(bpjs_kesehatan_channel).to receive(:create_transaction).and_return(bpjs_kesehatan_generalizer)
        expect(bpjs_kesehatan_subject).to receive(:partner_confirm_transaction_job)
        expect { bpjs_kesehatan_subject.run! }.not_to raise_error
      end
    end

    context 'when state not paid' do
      let(:bpjs_kesehatan_transaction) { create(:bpjs_kesehatan_transaction, :processed) }
      it 'raise error when state processed' do
        expect{ bpjs_kesehatan_subject.run! }.to raise_error(Exceptions::TransactionNotPaid)
      end
    end

    context "check transaction" do
      before(:each) do
        allow(bpjs_kesehatan_subject).to receive(:partner_channel).and_return(bpjs_kesehatan_channel)
      end

      it "should return true and nil if options without check is true" do
        action = Action::PostpaidTransaction::PartnerCreate.new(bpjs_kesehatan_transaction, without_check: true)
        expect(action.send(:check_transaction)).to eq(nil)
      end

      it "should return true and nil if result confirm_transaction is nil" do
        allow(bpjs_kesehatan_channel).to receive(:confirm_transaction).and_raise(Exceptions::PartnerTransactionNotFound)
        expect(bpjs_kesehatan_subject.send(:check_transaction)).to eq(nil)
      end

      it "should return false and response if result confirm_transaction is response" do
        allow(bpjs_kesehatan_channel).to receive(:confirm_transaction).and_return(response_channel_sepulsa)
        expect(bpjs_kesehatan_subject.send(:check_transaction)).to eq(response_channel_sepulsa)
      end
    end
  end

  context "pdam" do
    context "transaction" do
      before(:each) do
        pdam_transaction.remote_transaction_id = remote_transaction_id
        allow(pdam_subject).to receive(:partner_channel).and_return(pdam_channel)
      end

      it "should raise error if transaction state is not paid" do
        allow(pdam_transaction).to receive(:paid?).and_return(false)
        expect { pdam_subject.run! }.to raise_error(Exceptions::TransactionNotPaid)
      end

      it "should not raise error and spawn job confirm if transaction state is paid" do
        allow(pdam_subject).to receive(:check_transaction).and_return(nil)
        allow(pdam_channel).to receive(:create_transaction).and_return(pdam_generalizer)
        expect(pdam_subject).to receive(:partner_confirm_transaction_job)
        expect { pdam_subject.run! }.not_to raise_error
      end
    end

    context 'when state not paid' do
      let(:pdam_transaction) { create(:pdam_transaction_with_bill, :processed) }
      it 'raise error when state processed' do
        expect{ pdam_subject.run! }.to raise_error(Exceptions::TransactionNotPaid)
      end
    end

    context "check transaction" do
      before(:each) do
        allow(pdam_subject).to receive(:partner_channel).and_return(pdam_channel)
      end

      it "should return true and nil if options without check is true" do
        action = Action::PostpaidTransaction::PartnerCreate.new(pdam_transaction, without_check: true)
        expect(action.send(:check_transaction)).to eq(nil)
      end

      it "should return true and nil if result confirm_transaction is nil" do
        allow(pdam_channel).to receive(:confirm_transaction).and_raise(Exceptions::PartnerTransactionNotFound)
        expect(pdam_subject.send(:check_transaction)).to eq(nil)
      end

      it "should return false and response if result confirm_transaction is response" do
        allow(pdam_channel).to receive(:confirm_transaction).and_return(response_channel_sepulsa)
        expect(pdam_subject.send(:check_transaction)).to eq(response_channel_sepulsa)
      end
    end
  end
end
