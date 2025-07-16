require 'rails_helper'

RSpec.describe ResponseGeneralizer::ElectricityPostpaid, type: :model do
	let(:response_generalizer) { { } }
	let(:partner) { { } }
	let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
	let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin) }
	let(:response) {
		{
			customer_number: '080989999',
			partner_transaction_id: '123'
		}
	}
	let(:bills) {
		[
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
    ]
	}
	let(:period) {
		[
			"2011-03-01",
      "2011-04-01"
		]
	}

	subject { described_class.new(response, partner) }

	before {
		expect(RedisOlympus).to receive(:get).and_return(expected_redis_response).twice
	 }

	context 'partner sepulsa' do
		let(:expected_redis_response) { MiddlemanResponseMapperUtility::SepulsaRC::BILL_ALREADY_PAID_OR_NOT_AVAILABLE }
		let(:partner) { partner_sepulsa }
		it 'return correct result' do
			subject.bills = bills
			expect(subject.admin_charge).to eq(partner.admin_charge * bills.count)
			expect(subject.bukalapak_commission).to eq(partner.bukalapak_commission * bills.count)
			expect(subject.period).to eq(period)
			expect(subject.partner_transaction_id).to eq(response[:partner_transaction_id])
			expect(subject.partner).to eq(partner.name)
			expect(subject.response_code).to eq(50002)
			expect(subject.failed_reason).to eq("sepulsa|50")
		end
	end

	context 'partner bukopin' do
		let(:expected_redis_response) { MiddlemanResponseMapperUtility::BukopinRC::UNKNOWN_SUBSCRIBER }
		let(:partner) { partner_bukopin }
		it 'return correct result' do
			subject.bills = bills
			expect(subject.admin_charge).to eq(partner.admin_charge * bills.count)
			expect(subject.bukalapak_commission).to eq(partner.bukalapak_commission * bills.count)
			expect(subject.period).to eq(period)
			expect(subject.partner_transaction_id).to eq(response[:partner_transaction_id])
			expect(subject.partner).to eq(partner.name)
			expect(subject.response_code).to eq(50002)
			expect(subject.failed_reason).to eq("bukopin|0014")
		end
	end
end
