require "rails_helper"

RSpec.describe Action::ElectricityTransaction::Create, type: :model do
  let(:customer_number) { 512345600003 }
  let(:form) { Form::ElectricityPostpaid.new(customer_number) }
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  subject { Action::ElectricityTransaction::Create.new(form, 1, 0) }
  let(:invalid_inquiry) {
    {
      customer_number: '512345600003'
    }
  }
  let(:valid_inquiry) {
    {
      customer_number: '512345610000',
      customer_name: 'SERTU SABARIYANTO',
      segmentation: 'R1',
      power: 900,
      stand_meter: '00017822 - 00017915',
      outstanding_bill: 1,
      period: ['2011-03-01'],
      penalty_fee: 0,
      admin_charge: 1500,
      bukalapak_commission: 3000,
      amount: 42100,
      partner_transaction_id: "2214",
      partner: 'sepulsa',
      bills: [
        {
          bill_period: '2011-03-01',
          due_date: '2011-03-20',
          penalty_fee: 0,
          amount: 40500,
          previous_meter: '00017822',
          current_meter: '00017915'
        }
      ]
    }
  }
  let(:expected_inquiry_response) {
    JSON.parse({
      customer_number: "512345600003",
      customer_name: "SERTU SABARIYANTO",
      segmentation: "R1",
      power: 900,
      outstanding_bill: 2,
      unpaid_bill: nil,
      admin_charge: 3000,
      penalty_fee: 3500 + 7500,
      reference_number: nil,
      period: [
        "2011-03-01",
        "2011-04-01"
      ],
      # total amount is calculated bills amount plus admin charge plus penalty fee
      amount: 40500 + 3000 + 11000,
      bills: [
        {
          bill_period: "2011-03-01",
          penalty_fee: 3500,
          amount: 20500
        },
        {
          bill_period: "2011-04-01",
          penalty_fee: 7500,
          amount: 20000
        }
      ],
      partner: {
        name: 'PT Sepulsa Teknologi Indonesia'
      }
    }.to_json).with_indifferent_access
  }
  let(:inquiry_response) {
    {
      subscriber_id: '512345600003',
      subscriber_name: 'SERTU SABARIYANTO',
      subscriber_segmentation: 'R1',
      power: '900',
      stand_meter_summary: '00017822 - 00017915',
      bill_status: 2,
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

  before {
    allow(Time.zone).to receive(:now).and_return(Time.zone.parse("01:01"))
  }

  context "get inquiry" do
    it "should inquire again" do
      expect_any_instance_of(Action::PostpaidTransaction::Inquiry).to receive(:run!).and_return(inquiry_response)
      expect(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
      expect(subject.send(:get_inquiry)).to eq(inquiry_response)
    end
  end

  context "create transaction" do
    it "should raise error if inquiry cache is not valid" do
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(invalid_inquiry)
      allow(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
      allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
      allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
      expect { subject.run! }.to raise_error(Exceptions::CreateTransactionError)
    end

    it "should not raise error if inquiry cache is valid" do
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
      allow(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
      allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
      allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
      expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
        id: 1
      })

      expect { subject.run! }.not_to raise_error
    end
  end

  context 'create mass bill transaction' do
    let(:form) { Form::ElectricityPostpaid.new(customer_number, nil, nil, nil, "a987fbc9-4bed-3078-cf07-9141ba07c9f3") }
    it "should raise error if inquiry cache is not valid" do
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(invalid_inquiry)
      allow(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
      allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
      allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
      expect { subject.run! }.to raise_error(Exceptions::CreateTransactionError)
    end

    it "should not raise error if inquiry cache is valid" do
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
      allow(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
      allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
      allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
      expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
        id: 1
      })

      expect { subject.run! }.not_to raise_error
    end
  end
end
