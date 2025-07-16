require "rails_helper"
require 'examples/ayoconnect_examples'

RSpec.describe Channel::Ayoconnect::Helpers::ResponseNormalizer::ElectricityPostpaid, type: :model do
  class TesterClass
    include Channel::Ayoconnect::Helpers::ResponseNormalizer::ElectricityPostpaid
  end

  include_context 'ayoconnect_lets'

  describe '.fetch_customer_info' do
    subject do
      test_instance = TesterClass.new
      test_instance.fetch_customer_info(valid_inquiry_response)
    end

    let(:expected_results) {
      {
        customer_name: "JOENET LEMBAYUNG",
        customer_number: "516070377764",
        segmentation: "A1",
        power: "000000550",
        stand_meter: "01076100 - 01112300",
        outstanding_bill: "3 Bulan",
        unpaid_bill: "3 Bulan",
        amount: 95539,
        admin_charge: 6000,
        penalty_fee: 12000,
        bills: [
          {
            bill_period: ::Converter::StringToDate.convert('JAN2016', string_format: ::Postpaid::Constant::MMMYYYY),
            due_date: ::Converter::StringToDate.convert('20-Feb-2016', string_format: ::Postpaid::Constant::DDMMMYYYY),
            amount: 32661,
            penalty_fee: 6000,
            previous_meter: '01076100',
            current_meter: '01084300'
          },
          {
            bill_period: ::Converter::StringToDate.convert('FEB2016', string_format: ::Postpaid::Constant::MMMYYYY),
            due_date: ::Converter::StringToDate.convert('20-Mar-2016', string_format: ::Postpaid::Constant::DDMMMYYYY),
            amount: 43878,
            penalty_fee: 3000,
            previous_meter: '01084300',
            current_meter: '01094700'
          },
          {
            bill_period: ::Converter::StringToDate.convert('MAR2016', string_format: ::Postpaid::Constant::MMMYYYY),
            due_date: ::Converter::StringToDate.convert('20-Apr-2016', string_format: ::Postpaid::Constant::DDMMMYYYY),
            amount: 7000,
            penalty_fee: 3000,
            previous_meter: '01094700',
            current_meter: '01112300'
          }
        ]
      }
    }

    it 'returns hash containing expected keys' do
      expect(subject).to have_key(:customer_name)
      expect(subject).to have_key(:customer_number)
      expect(subject).to have_key(:segmentation)
      expect(subject).to have_key(:power)
      expect(subject).to have_key(:stand_meter)
      expect(subject).to have_key(:outstanding_bill)
      expect(subject).to have_key(:unpaid_bill)
      expect(subject).to have_key(:amount)
      expect(subject).to have_key(:admin_charge)
      expect(subject).to have_key(:penalty_fee)
      expect(subject).to have_key(:bills)
    end

    it 'returns expected results' do
      expect(subject).to eq expected_results
    end
  end
end
