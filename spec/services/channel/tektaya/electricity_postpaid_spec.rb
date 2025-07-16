require 'rails_helper'
require 'examples/tektaya_examples'

# used in both inquiry and payment
def inquiry_failed_test_cases
  [
    {
      name: 'bill already paid',
      partner_response: bill_already_paid_inquiry_response,
      error_raised: ::Exceptions::BillAlreadyPaid
    },
    {
      name: 'bill unavailable',
      partner_response: bill_unavailable_inquiry_response,
      error_raised: ::Exceptions::BillAlreadyPaid
    },
    {
      name: 'bill exceed limit',
      partner_response: bill_exceed_limit_inquiry_response,
      error_raised: ::Exceptions::BillExceedLimit
    },
    {
      name: 'unregistered number',
      partner_response: unregistered_number_inquiry_response,
      error_raised: ::Exceptions::UnregisteredNumber
    },
    {
      name: 'general error',
      partner_response: failed_inquiry_response,
      error_raised: ::Exceptions::DefaultError
    }
  ]
end

RSpec.shared_examples 'an inquiry request' do
  context 'when success request' do
    before do
      allow(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya).to receive(:active?).and_return(false)
      allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
    end

    context 'with single bill' do
      let(:partner_response) { valid_single_bill_inquiry_response.to_json }

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns inquiry data' do
        result = subject

        # all of the values here is taken from tektaya_examples
        expect(result.customer_number).to eq '512110000003'
        expect(result.customer_name).to eq "DU''MMY-4DEFWWC8WIJH6"
        expect(result.segmentation).to eq 'I2'
        expect(result.power).to eq 450
        expect(result.stand_meter).to eq '00008888 - 00008899'
        expect(result.outstanding_bill).to eq 1
        expect(result.unpaid_bill).to eq 1
        expect(result.penalty_fee).to eq 0
        expect(result.amount).to eq (79_538 + result.admin_charge)
        expect(result.bills.length).to eq 1
      end
    end

    context 'with multi bill' do
      let(:partner_response) { valid_multi_bill_inquiry_response.to_json }

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns inquiry data' do
        result         = subject
        expected_bills = [
          {
            bill_period: Date.new(2020, 12).beginning_of_month,
            bill_due_date: Date.new(2020, 12, 20),
            amount: 53_952,
            penalty_fee: 9_000,
            previous_meter: '00008888',
            current_meter: '00008899'
          },
          {
            bill_period: Date.new(2021, 1).beginning_of_month,
            bill_due_date: Date.new(2021, 1, 20),
            amount: 69_350,
            penalty_fee: 9_000,
            previous_meter: '00008899',
            current_meter: '00008910'
          },
          {
            bill_period: Date.new(2021, 2).beginning_of_month,
            bill_due_date: Date.new(2021, 2, 20),
            amount: 73_925,
            penalty_fee: 9_000,
            previous_meter: '00008910',
            current_meter: '00008921'
          },
          {
            bill_period: Date.new(2021, 3).beginning_of_month,
            bill_due_date: Date.new(2021, 3, 20),
            amount: 53_713,
            penalty_fee: 6_000,
            previous_meter: '00008921',
            current_meter: '00008932'
          }
        ]

        # all of the values here is taken from tektaya_examples
        expect(result.customer_number).to eq '512510000001'
        expect(result.customer_name).to eq "DU''MMY-71SUFJPC73K9B"
        expect(result.segmentation).to eq 'R1'
        expect(result.power).to eq 450
        expect(result.stand_meter).to eq "00008888 - 00008932"
        expect(result.outstanding_bill).to eq 4
        expect(result.unpaid_bill).to eq 4
        expect(result.penalty_fee).to eq expected_bills.sum { |bill| bill[:penalty_fee] }
        expect(result.amount).to eq (expected_bills.sum { |bill| bill[:amount] }) + result.penalty_fee + result.admin_charge
        expect(result.bills.length).to eq 4
        expect(result.bills).to eq expected_bills
      end
    end
  end

  context 'when response is failed' do
    it 'raise error for the respective errors' do
      inquiry_failed_test_cases.each do |tc|
        allow(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya).to receive(:active?).and_return(false)
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(tc[:partner_response].to_json)
        expect { subject }.to raise_error tc[:error_raised]
      end
    end
  end
end

RSpec.shared_examples 'a payment request' do
  before do
    allow(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya).to receive(:active?).and_return(false)
    allow(Channel::Connection::Http).to receive_message_chain(:post).with(
      anything,
      nil,
      hash_including(:kdproduk, :userid, :password, :bit62, :sessionkey, :idpel, :trxid, :mti => '38'),
      anything,
      anything
    ).and_return(inquiry_raw_response)

    allow(Channel::Connection::Http).to receive_message_chain(:post).with(
      anything,
      nil,
      hash_including(:kdproduk, :userid, :password, :bit62, :sessionkey, :idpel, :trxid, :mti => '17'),
      anything,
      anything
    ).and_return(payment_raw_response)
  end

  context 'when success request' do
    let(:inquiry_raw_response) { double 'inquiry response' }
    let(:payment_raw_response) { double 'payment response' }

    before do
      allow(inquiry_raw_response).to receive(:body).and_return(inquiry_partner_response)
      allow(payment_raw_response).to receive(:body).and_return(payment_partner_response)
    end

    context 'with single bill' do
      let(:inquiry_partner_response) { valid_single_bill_inquiry_response.to_json }
      let(:payment_partner_response) { valid_single_bill_create_response.to_json }

      # single bill response uses amount of 82.038
      before do
        transaction.amount = 82_038
        transaction.save
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns payment data' do
        result = subject

        # all of the values here is taken from tektaya_examples
        expect(result.status).to eq ::Postpaid::Constant::SUCCESS
        expect(result.partner_transaction_id).to eq '738263767'
        expect(result.reference_number).to eq '1TKT2121AF1EE8C1354BDBAFD6A0DB5A'
        expect(result.info_text).to eq '~Informasi Hubungi Call Center 123~Atau Hub PLN Terdekat : '
      end
    end

    context 'with multi bill' do
      let(:inquiry_partner_response) { valid_multi_bill_inquiry_response.to_json }
      let(:payment_partner_response) { valid_multi_bill_create_response.to_json }

      # multi bill response uses amount of 293.940
      before do
        transaction.amount = 293_940
        transaction.save
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns payment data' do
        result = subject

        # all of the values here is taken from tektaya_examples
        expect(result.status).to eq ::Postpaid::Constant::SUCCESS
        expect(result.partner_transaction_id).to eq '738263777'
        expect(result.reference_number).to eq '1TKT21CB63CFCF44D942F2B5B66AC71D'
        expect(result.info_text).to eq '~Informasi Hubungi Call Center 123~Atau Hub PLN Terdekat : '
      end
    end
  end

  context 'when response is failed' do
    let(:inquiry_raw_response) { double 'inquiry response' }
    let(:payment_raw_response) { double 'payment response' }

    context 'when inquiry error' do
      it 'raise error for the respective errors' do
        inquiry_failed_test_cases.each do |tc|
          expect(inquiry_raw_response).to receive(:body).and_return(tc[:partner_response].to_json)
          expect { subject }.to raise_error(tc[:error_raised])
          expect(transaction.state).to eq 'paid'
        end
      end
    end

    context 'when amount mismatch between partner and transaction' do
      # simulate different amount
      before do
        transaction.amount = 999_999
        transaction.save
      end

      it 'raises amount mismatch error' do
        expect(inquiry_raw_response).to receive(:body).and_return(valid_single_bill_inquiry_response.to_json)
        expect { subject }.to raise_error(Exceptions::AmountMismatch)
      end
    end

    context 'when payment error' do
      before do
        allow(inquiry_raw_response).to receive(:body).and_return(valid_single_bill_inquiry_response.to_json)
        allow(payment_raw_response).to receive(:body).and_return(failed_create_response.to_json)

        # single bill response uses amount of 82.038
        transaction.amount = 82_038
        transaction.save
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns payment data' do
        result = subject

        expect(result.status).to eq ::Postpaid::Constant::FAILED
      end
    end

    context 'when payment got timeout' do
      before do
        allow(inquiry_raw_response).to receive(:body).and_return(valid_single_bill_inquiry_response.to_json)
        allow(payment_raw_response).to receive(:body).and_return(timeout_create_response.to_json)

        # single bill response uses amount of 82.038
        transaction.amount = 82_038
        transaction.save
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns payment data' do
        result = subject

        expect(result.status).to eq ::Postpaid::Constant::PENDING
      end
    end
  end
end

RSpec.describe Channel::Tektaya::ElectricityPostpaid, type: :model do
  include_context 'tektaya_lets'

  let(:customer_number) { "516070377764" }
  let(:url) { 'https://somewhat.com/n/v7/pln-postpaid' }
  let(:partner_tektaya) { build_stubbed(:electricity_postpaid_partner, :tektaya) }

  before do
    allow(::ElectricityPostpaidPartner).to receive(:find_by).with(name: 'tektaya').and_return(partner_tektaya)
  end

  describe '#inquiry_to_partner' do
    context 'with unexpected object' do
      subject { described_class.new(::PdamTransaction.new).inquiry_to_partner }

      it 'raises general error due to unexpected object' do
        expect { subject }.to raise_error(::Exceptions::GeneralError)
      end
    end

    context 'with MITRA buyer type' do
      let(:form) { Form::ElectricityPostpaid.new(customer_number, nil, 'tektaya', Postpaid::Constant::AGENT_BUYER_TYPE) }

      subject { described_class.new(form).inquiry_to_partner }

      before do
        expect(RedisOlympus).to receive(:get).with(Channel::Tektaya::Helpers::Constants::BMI_SESSION_KEY).at_least(1).times.and_return('key')
      end

      it_behaves_like 'an inquiry request'
    end

    context 'with NORMAL buyer type' do
      let(:form) { Form::ElectricityPostpaid.new(customer_number, nil, 'tektaya', Postpaid::Constant::NORMAL_BUYER_TYPE) }

      subject { described_class.new(form).inquiry_to_partner }

      before do
        expect(RedisOlympus).to receive(:get).with(Channel::Tektaya::Helpers::Constants::BL_SESSION_KEY).at_least(1).times.and_return('key')
      end

      it_behaves_like 'an inquiry request'
    end
  end

  describe '#create_transaction' do
    context 'with unexpected object' do
      subject { described_class.new(::PdamTransaction.new).create_transaction }

      it 'raises general error due to unexpected object' do
        expect { subject }.to raise_error(::Exceptions::GeneralError)
      end
    end

    context 'with MITRA buyer type' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :partner_tektaya, state: 'processed', customer_number: '512110000003', transaction_type: 'agent') }

      subject { described_class.new(transaction).create_transaction }

      before do
        expect(RedisOlympus).to receive(:get).with(Channel::Tektaya::Helpers::Constants::BMI_SESSION_KEY).at_least(1).times.and_return('key')
      end

      it_behaves_like 'a payment request'
    end

    context 'with NORMAL buyer type' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :partner_tektaya, state: 'processed', customer_number: '512510000001', transaction_type: 'normal') }

      subject { described_class.new(transaction).create_transaction }

      before do
        expect(RedisOlympus).to receive(:get).with(Channel::Tektaya::Helpers::Constants::BL_SESSION_KEY).at_least(1).times.and_return('key')
      end

      it_behaves_like 'a payment request'
    end
  end
end
