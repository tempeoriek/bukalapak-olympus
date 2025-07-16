require "rails_helper"

RSpec.describe Action::PostpaidTransaction::Inquiry, type: :model do
  let(:electricity_customer_number) { '512345600003' }
  let(:bpjs_kesehatan_customer_number) { '0000001430071801' }
  let(:pdam_customer_number) { '1998900001' }
  let(:invalid_payment_period) { '13' }
  let(:valid_payment_period) { '01' }
  let(:invalid_operator_id) { 100 }
  let(:valid_operator_id) { 1 }
  let(:electricity_form) { Form::ElectricityPostpaid }
  let(:bpjs_kesehatan_form) { Form::BpjsKesehatan }
  let(:pdam_form) { Form::Pdam }
  let(:electricity_channel) { Channel::Sepulsa::ElectricityPostpaid }
  let(:bpjs_kesehatan_channel) { Channel::Sepulsa::BpjsKesehatan }
  let(:bpjs_kesehatan_partner) { build_stubbed(:bpjs_kesehatan_partner) }
  let(:pdam_channel) { Channel::Sepulsa::Pdam }
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  let(:pdam_operator) {
    build_stubbed(:pdam_operator)
  }
  let(:electricity_inquiry_response) {
    {
      subscriber_id: '512345600003',
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
  let(:electricity_postpaid_inquiry_response) {
    result = ResponseGeneralizer::ElectricityPostpaid.new(electricity_inquiry_response, partner_sepulsa)
    result.bills = electricity_expected_inquiry_response[:bills]
    result.customer_number = electricity_inquiry_response[:subscriber_id]&.strip
    result.customer_name = electricity_inquiry_response[:subscriber_name]&.strip
    result.segmentation = electricity_inquiry_response[:subscriber_segmentation]
    result.power = electricity_inquiry_response[:power].to_i
    result.stand_meter = electricity_inquiry_response[:stand_meter_summary]
    result.outstanding_bill = electricity_inquiry_response[:bill_status].to_i
    result.unpaid_bill = electricity_inquiry_response[:outstanding_bill].to_i
    result.penalty_fee = 3500 + 7500
    result.amount = 40500 + result.admin_charge + 11000
    result.reference_number = electricity_inquiry_response[:switcher_refno]
    result
  }
  let(:electricity_expected_inquiry_response) {
    {
      customer_number: "512345600003",
      customer_name: "SERTU SABARIYANTO",
      segmentation: "R1",
      power: 900,
      stand_meter: "00017822 - 00017915",
      outstanding_bill: 2,
      admin_charge: 2 * 1500,
      partner: "sepulsa",
      penalty_fee: 3500 + 7500,
      period: [
        Converter::StringToDate.convert("201103", string_format: "yyyymm"),
        Converter::StringToDate.convert("201104", string_format: "yyyymm")
      ],
      # total amount is calculated bills amount plus admin charge plus penalty fee
      amount: 40500 + 3000 + 11000,
      bills: [
        {
          bill_period: Converter::StringToDate.convert("201103", string_format: "yyyymm"),
          due_date: Converter::StringToDate.convert("20110320"),
          penalty_fee: 3500,
          amount: 20500,
          previous_meter: "00017822",
          current_meter: "00017915"
        },
        {
          bill_period: Converter::StringToDate.convert("201104", string_format: "yyyymm"),
          due_date: Converter::StringToDate.convert("20110420"),
          penalty_fee: 7500,
          amount: 20000,
          previous_meter: "00017822",
          current_meter: "00017915"
        }
      ]
    }
  }
  let(:bpjs_kesehatan_inquiry_response) {
    {
      name: 'ANISA KARTIKA INDIARTI (PST:  1)',
      no_va: '0000001430071801',
      nama_cabang: 'SEMARANG',
      premi: '51000',
      periode: '01',
      paid_until: '2017-10'
    }
  }
  let(:pdam_inquiry_response) {
    {
      idpel: '1998900001',
      name: 'JUNAIDI XX001                 ',
      amount: 11110,
      admin_charge: 0,
      blth: "201201201201",
      bill_count: '01',
      bill_repeat_count: '01',
      bills: [
        {
          bill_date: ['201201'],
          bill_amount: ['000000011110'],
          penalty: ["00000000"],
          kubikasi: ["00000402-00000458"]
        }
      ]
    }
  }
  let(:bpjs_kesehatan_expected_inquiry_response) {
    {
      customer_number: '0000001430071801',
      customer_name: 'ANISA KARTIKA INDIARTI',
      family_member_count: 1,
      branch_name: "SEMARANG",
      amount: 52500,
      admin_charge: 1500,
      payment_period: "01",
      partner: 'sepulsa',
      paid_until:{month:11, year: 2017}
    }
  }
  let(:pdam_expected_inquiry_response) {
    {
      customer_number: '1998900001',
      customer_name: 'JUNAIDI XX001',
      penalty_fee: 0,
      amount: 13110,
      partner: 'sepulsa',
      admin_charge: 2000,
      start_bill_period: Converter::StringToDate.convert("201201", string_format: "yyyymm"),
      end_bill_period: Converter::StringToDate.convert("201201", string_format: "yyyymm"),
      operator: {
        id: pdam_operator.id,
        name: 'Denpasar',
        group: 'Bali',
        image_url: 'http://i0.kym-cdn.com/entries/icons/mobile/000/013/564/doge.jpg'
      },
      bills: [
        {
          bill_period: Converter::StringToDate.convert("201201", string_format: "yyyymm"),
          amount: 11110,
          penalty_fee: 0,
          cubication: "00000402-00000458",
          usage: 56
        }
      ],
      usage: 56
    }
  }

  subject { Action::PostpaidTransaction::Inquiry }

  before {
    allow(Time.zone).to receive(:now).and_return(Time.parse("01:01"))
    allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
    allow(Action::PdamAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
    allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
  }

  context "electricity postpaid" do
    context "inquiry response" do
      it "should not raise error and return expected result" do
        allow(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
        form = electricity_form.new(electricity_customer_number)
        channel = electricity_channel.new(form)

        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(electricity_inquiry_response)
        expect(channel.inquiry_to_partner.as_json).to eq(electricity_postpaid_inquiry_response.as_json)
        expect { subject.new(form).run! }.not_to raise_error
      end
    end
  end

  context "bpjs kesehatan" do
    it "should not raise error if payment period is valid" do
      allow(Time).to receive(:now).and_return(Time.new(2017, 10))
      allow(BpjsKesehatanPartner).to receive(:find_by).and_return(bpjs_kesehatan_partner)
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(bpjs_kesehatan_inquiry_response)
      allow(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(false)

      form = bpjs_kesehatan_form.new(bpjs_kesehatan_customer_number, valid_payment_period)
      channel = bpjs_kesehatan_channel.new(form)

      expect(channel.inquiry_to_partner).to be_an_instance_of(ResponseGeneralizer::BpjsKesehatan)
      expect { subject.new(form).run! }.not_to raise_error
    end
  end

  context "pdam" do
    it "should not raise error" do
      allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
      form = pdam_form.new(pdam_customer_number, valid_operator_id)
      channel = pdam_channel.new(form)

      allow_any_instance_of(Channel::Sepulsa::Pdam).to receive(:inquiry).and_return(pdam_inquiry_response)
      expect(channel.inquiry_to_partner).to be_an_instance_of(ResponseGeneralizer::Pdam)
      expect { subject.new(form).run! }.not_to raise_error
    end
  end
end
