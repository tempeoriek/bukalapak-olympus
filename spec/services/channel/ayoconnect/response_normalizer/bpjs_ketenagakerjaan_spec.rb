require "rails_helper"
require 'examples/ayoconnect_examples'

RSpec.describe Channel::Ayoconnect::Helpers::ResponseNormalizer::BpjsKetenagakerjaan, type: :model do
  class ResponseNormalizerBpjsKetenagakerjaanMockClass
    include Channel::Ayoconnect::Helpers::ResponseNormalizer::BpjsKetenagakerjaan
  end

  include_context 'ayoconnect_lets'

  describe 'O2OVPD-1497: .fetch_customer_info' do
    context 'when type is bpu' do
      
      context 'when no unpaid bills' do
        subject do
          test_instance = ResponseNormalizerBpjsKetenagakerjaanMockClass.new
          test_instance.fetch_customer_info(valid_bpjs_ketenagakerjaan_bpu_inquiry_response, :bpu)
        end
  
        let(:expected_results) {
          {
            customer_name: 'NICO JULIAN',
            customer_number: '1871010907930009',
            amount: 36_800,
            admin_charge: 0,
            bill_code: 'N/A',
            start_bill_period: Date.new(2021, 8, 27),
            end_bill_period: Date.new(2021, 9, 26),
            branch_name: 'JAKARTA GROGOL',
            bills: [
              {
                amount: 36_800,
                jht: 20_000,
                jkk: 10_000,
                jkm: 6_800
              },
            ],
            unpaid_bills: false,
            unpaid_bills_text: ''
          }
        }
  
        it 'returns hash containing expected keys' do
          expect(subject).to have_key(:customer_name)
          expect(subject).to have_key(:customer_number)
          expect(subject).to have_key(:amount)
          expect(subject).to have_key(:admin_charge)
          expect(subject).to have_key(:bills)
          expect(subject).to have_key(:start_bill_period)
          expect(subject).to have_key(:end_bill_period)
          expect(subject).to have_key(:bill_code)
          expect(subject).to have_key(:branch_name)
          expect(subject).to have_key(:unpaid_bills)
          expect(subject).to have_key(:unpaid_bills_text)
        end
  
        it 'returns expected results' do
          expect(subject).to eq expected_results
        end
      end
      
      context 'when have unpaid bills' do
        subject do
          test_instance = ResponseNormalizerBpjsKetenagakerjaanMockClass.new
          test_instance.fetch_customer_info(valid_bpjs_ketenagakerjaan_bpu_inquiry_response_with_tunggakan, :bpu)
        end

        let(:expected_results) {
          {
            customer_name: 'NICO JULIAN',
            customer_number: '1871010907930009',
            amount: 36_800,
            admin_charge: 0,
            bill_code: '921083112662',
            start_bill_period: Date.new(2021, 8, 27),
            end_bill_period: Date.new(2021, 9, 26),
            branch_name: 'JAKARTA GROGOL',
            bills: [
              {
                amount: 36_800,
                jht: 20_000,
                jkk: 10_000,
                jkm: 6_800
              },
            ],
            unpaid_bills: true,
            unpaid_bills_text: 'Total Iuran diatas merupakan nominal dari kode iuran yang belum terbayarkan sebelumnya.'
          }
        }

        it 'returns hash containing expected keys' do
          expect(subject).to have_key(:customer_name)
          expect(subject).to have_key(:customer_number)
          expect(subject).to have_key(:amount)
          expect(subject).to have_key(:admin_charge)
          expect(subject).to have_key(:bills)
          expect(subject).to have_key(:start_bill_period)
          expect(subject).to have_key(:end_bill_period)
          expect(subject).to have_key(:bill_code)
          expect(subject).to have_key(:branch_name)
          expect(subject).to have_key(:unpaid_bills)
          expect(subject).to have_key(:unpaid_bills_text)
        end
  
        it 'returns expected results' do
          expect(subject).to eq expected_results
        end
      end
    end

    context 'when type is pu' do
      subject do
        test_instance = ResponseNormalizerBpjsKetenagakerjaanMockClass.new
        test_instance.fetch_customer_info(valid_bpjs_ketenagakerjaan_pu_inquiry_response, :pu)
      end

      let(:expected_results) {
        {
          customer_name: 'JKP EMPAT',
          customer_number: '210800004501',
          amount: 108_990,
          admin_charge: 2_500,
          start_bill_period: Date.new(2021, 9, 1),
          end_bill_period: Date.new(2021, 9, 30),
          npp: '21000104',
          division: '000',
          bills: [
            {
              amount: 108_990,
              jht: 63_167,
              jkk: 17_269,
              jkm: 3_787,
              jkp: 0,
              jp: 24_767
            },
          ],
          unpaid_bills: false,
        }
      }

      it 'returns hash containing expected keys' do
        expect(subject).to have_key(:customer_name)
        expect(subject).to have_key(:customer_number)
        expect(subject).to have_key(:amount)
        expect(subject).to have_key(:admin_charge)
        expect(subject).to have_key(:bills)
        expect(subject).to have_key(:start_bill_period)
        expect(subject).to have_key(:end_bill_period)
        expect(subject).to have_key(:npp)
        expect(subject).to have_key(:division)
        expect(subject).to have_key(:unpaid_bills)
      end

      it 'returns expected results' do
        expect(subject).to eq expected_results
      end
    end
  end
end
