require "rails_helper"

RSpec.describe Action::PdamTransaction::Create, type: :model do
  let(:customer_number) { '1998900001' }
  let(:operator) { build_stubbed(:pdam_operator) }
  subject { Action::PdamTransaction::Create.new(Form::Pdam.new(customer_number, operator.id), 1, 0) }
  let(:bills) {
    [
      {
        "amount": 11110,
        "bill_period": ::Converter::StringToDate.convert("201201", string_format: 'yyyymm'),
        "cubication": "00000402-00000458",
        "penalty_fee": 0,
        "usage": 56
      }
    ]
  }
  let(:bills_with_non_tagair) {
    [
      {
        "amount": 1550000,
        "bill_period": nil,
        "cubication": "0-0",
        "penalty_fee": 0,
        "usage": 0
      },
      {
        "amount": 11110,
        "bill_period": ::Converter::StringToDate.convert("201201", string_format: 'yyyymm'),
        "cubication": "00000402-00000458",
        "penalty_fee": 0,
        "usage": 56
      }
    ]
  }
  let(:bills_only_non_tagair) {
    [
      {
        "amount": 1550000,
        "bill_period": nil,
        "cubication": "0-0",
        "penalty_fee": 0,
        "usage": 0
      }
    ]
  }
  let(:failed_partner_response) {
    r = ResponseGeneralizer::Pdam.new

    r.customer_number = '1998800001'
    r
  }

  let(:success_partner_response) {
    r = ResponseGeneralizer::Pdam.new

    r.customer_number = "1998800007"
    r.customer_name = "Putin"
    r.penalty_fee = 0
    r.start_bill_period = Date.new(2012, 1)
    r.end_bill_period = Date.new(2012, 1)
    r.partner = 'sepulsa'
    r.amount = 13610
    r.bukalapak_admin_charge = Test::BUKALAPAK_ADMIN_CHARGE
    r.partner_admin_charge = Test::PARTNER_ADMIN_CHARGE
    r.bills = bills
    r.usage = 56
    r.operator = operator

    r
  }

  let(:success_partner_response_with_non_tagair) {
    success_partner_response.bills = bills_with_non_tagair
    success_partner_response.bukalapak_admin_charge = Test::BUKALAPAK_ADMIN_CHARGE * 2
    success_partner_response.partner_admin_charge = Test::PARTNER_ADMIN_CHARGE * 2
    success_partner_response
  }

  let(:success_partner_response_only_non_tagair) {
    success_partner_response.bills = bills_only_non_tagair
    success_partner_response.start_bill_period = Date.new(2012, 1)
    success_partner_response.end_bill_period = Date.new(2012, 1)

    success_partner_response
  }

  describe '.run' do
    before do
      allow(PdamOperator).to receive(:find_by_id).and_return(operator)
      allow_any_instance_of(PdamTransaction).to receive(:operator).and_return(operator)
    end

    context 'when inquiry successful' do

      context 'without details' do
        it 'could create transaction' do
          allow(subject).to receive(:get_inquiry).and_return(success_partner_response)
          expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
            id: 1
          })
          result = subject.run!
          expect { result }.not_to raise_error
          expect(result.details).to eq({}) # empty details
        end
      end

      context 'with details' do
        let(:success_partner_response) do
          r = ResponseGeneralizer::Pdam.new

          r.customer_number = "1998800007"
          r.customer_name = "Putin"
          r.penalty_fee = 0
          r.start_bill_period = Date.new(2012, 1)
          r.end_bill_period = Date.new(2012, 1)
          r.partner = 'sepulsa'
          r.amount = 13610
          r.bukalapak_admin_charge = Test::BUKALAPAK_ADMIN_CHARGE
          r.partner_admin_charge = Test::PARTNER_ADMIN_CHARGE
          r.bills = bills
          r.usage = 56
          r.operator = operator
          r.details = { sub_segment: '3A', biller_ref: '00001' }

          r
        end

        it 'could create transaction' do
          allow(subject).to receive(:get_inquiry).and_return(success_partner_response)
          expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
            id: 1
          })

          result = subject.run!
          expect { result }.not_to raise_error
          expect(result.details).to eq({ sub_segment: '3A', biller_ref: '00001' }.with_indifferent_access)
        end
      end
    end

    context 'when inquiry successful with additional non-tagair bill' do
      it 'could create transaction' do
        allow(subject).to receive(:get_inquiry).and_return(success_partner_response_with_non_tagair)
        expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
          id: 1
        })

        expect { subject.run! }.not_to raise_error
      end
    end

    context 'when inquiry successful with only non-tagair bill' do
      it 'could create transaction' do
        allow(subject).to receive(:get_inquiry).and_return(success_partner_response_only_non_tagair)
        expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
          id: 1
        })

        expect { subject.run! }.not_to raise_error
      end
    end

    context 'when inquiry unsuccessful' do
      it 'raise error' do
        allow(subject).to receive(:get_inquiry).and_return(failed_partner_response)

        expect { subject.run! }.to raise_error(Exceptions::CreateTransactionError)
      end
    end

    context 'when inquiry errors' do
      it 'raise error' do
        allow(subject).to receive(:get_inquiry).and_raise(StandardError)

        expect { subject.run! }.to raise_error(StandardError)
      end
    end
  end
end
