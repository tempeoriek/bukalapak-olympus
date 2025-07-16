# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::GeneralCircuitBreaker, type: :model do
  subject {
    GeneralCircuitBreaker::CreditCardBill.instance
  }

  before {
    allow(Config::GeneralCircuitBreaker).to receive(:config).and_return(credit_card_bill: GeneralCircuitBreaker::CreditCardBill::CONFIG)
  }

  context 'O2OVPE-483: .incr' do
    let(:gmv) { 125_000 }
    let(:now) { Time.find_zone('Asia/Jakarta').local(2023, 10, 13, 16, 59, 0) }
    let(:next_hour) { (now.beginning_of_hour + 1.hour + 10.second).to_i }
    let(:redis) { RedisOlympus }

    before {
      allow(Time).to receive(:now).and_return(now)
    }

    context 'when success' do
      before {
        allow(redis).to receive(:incrby).with('credit-card-bill-hourly-trx:2023-10-13-16:00', 1).and_return(1)
        allow(redis).to receive(:expireat).with('credit-card-bill-hourly-trx:2023-10-13-16:00', next_hour).and_return(60)
        allow(redis).to receive(:incrby).with('credit-card-bill-hourly-gmv:2023-10-13-16:00', gmv).and_return(gmv)
        allow(redis).to receive(:expireat).with('credit-card-bill-hourly-gmv:2023-10-13-16:00', next_hour).and_return(60)
        allow(Observer).to receive(:counter) { true }
      }

      it 'returns true' do
        expect(subject.incr(gmv)).to be(true)
      end
    end

    context 'when redis error' do
      before {
        allow(redis).to receive(:incrby).and_raise(Redis::ConnectionError)
      }

      it 'fails silently' do
        expect(subject.incr(125000)).to be(false)
      end
    end
  end

  context 'O2OVPE-483: .allow?' do
    let(:trx) { 0 }
    let(:gmv) { 0 }
    let(:now) { Time.find_zone('Asia/Jakarta').local(2023, 10, 13, 16, 59, 0) }
    let(:redis) { RedisOlympus }

    before do
      allow(Time).to receive(:now).and_return(now)
      allow(redis).to receive(:get).with('credit-card-bill-hourly-trx:2023-10-13-16:00').and_return(trx)
      allow(redis).to receive(:get).with('credit-card-bill-hourly-gmv:2023-10-13-16:00').and_return(gmv)
    end

    context 'when gmv and trx below threshold' do
      it 'returns true' do
        expect(subject.allow?).to be(true)
      end
    end

    context 'when gmv above threshold' do
      let(:gmv) {  GeneralCircuitBreaker::CreditCardBill::CONFIG[:max_hourly_gmv]}

      it 'returns false' do
        expect(subject.allow?).to be(false)
      end
    end

    context 'when trx above threshold' do
      let(:trx) { GeneralCircuitBreaker::CreditCardBill::CONFIG[:max_hourly_trx]}
      it 'returns false' do
        expect(subject.allow?).to be(false)
      end
    end

    context 'when both gmv and trx above threshold' do
      let(:trx) { GeneralCircuitBreaker::CreditCardBill::CONFIG[:max_hourly_trx]}
      let(:gmv) { GeneralCircuitBreaker::CreditCardBill::CONFIG[:max_hourly_gmv]}

      it 'returns false' do
        expect(subject.allow?).to be(false)
      end
    end

    context 'when redis error' do
      it 'returns true' do
        expect(redis).to receive(:get).and_raise(Redis::ConnectionError)
        expect(subject.allow?).to be(true)
      end
    end
  end
end
