require 'rails_helper'

RSpec.describe Recurrence::ElectricityPostpaid::CreateTransaction, type: :model do

  let(:recurrence_template) { create(:electricity_postpaid_recurrence_template_detail) }
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  let(:user_deposit_data) { { withdrawable_balance: 100000 } }
  let(:inquiry_response) {
    {
      subscriber_id: '512345610000',
      subscriber_name: 'SERTU SABARIYANTO',
      subscriber_segmentation: 'R1',
      power: '900',
      stand_meter_summary: '00017822 - 00017915',
      bill_status: '1',
      bills: [
        {
          bill_period: '201103',
          due_date: '20110320',
          penalty_fee: '3500',
          total_electricity_bill: '20500',
          previous_meter_reading1: '00017822',
          current_meter_reading1: '00017915'
        },
        {
          bill_period: '201104',
          due_date: '20110420',
          penalty_fee: '7500',
          total_electricity_bill: '20000',
          previous_meter_reading1: '00017822',
          current_meter_reading1: '00017915'
        }
      ]
    }
  }
  let(:expected_transaction_data) {
    JSON.parse({
      remote_transaction_id: 1,
      customer_number: '512345610000',
      customer_name: 'SERTU SABARIYANTO',
      power: 900,
      penalty_fee: 11000,
      admin_charge: 3000,
      amount: 54500,
      state: 'pending'
    }.to_json)
  }
  let(:remote_id) {
    {
      id: 1
    }
  }
  before do
    allow(ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
    allow(Escrow::Connection).to receive(:post).with(anything, anything).and_return(true)
    allow_any_instance_of(Escrow::RetrieveDeposit).to receive(:run!).and_return(user_deposit_data)
    allow(Time.zone).to receive(:now).and_return(Time.parse("01:01"))
    allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
    allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
  end

  describe 'run!' do
    context 'success' do
      subject { described_class.new(recurrence_template.id) }

      before do
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
        allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(remote_id)
      end

      it 'not raising error' do
        expect { subject.run! }.not_to raise_error
      end

      it 'returns correct json' do
        result = subject.run!
        expect(result.as_json).to include(expected_transaction_data)
      end
    end

    context 'failed' do
      context 'no record' do
        subject { described_class.new(recurrence_template.id+1) }
        it 'raise error' do
          expect { subject.run! }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

end
