require "rails_helper"

RSpec.describe Action::ElectricityTransaction::Exclusive::DeductBalance, type: :model do
  let(:partner_object_stub) { build_stubbed(:electricity_postpaid_partner, :tektaya) }

  before do
    allow(ElectricityPostpaidPartner).to receive(:find_by).and_return partner_object_stub
  end

  describe '#run!' do
    context 'when the partner is bukopin' do
      context 'when the transaction type is normal' do
        let(:transaction_stub) { build_stubbed(:postpaid_transaction_with_bill, :partner_bukopin) }

        before do
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_balance_bukopin, 9911500)
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_threshold_bukopin, 1000000)
        end

        it 'hit the metric correctly' do
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(transaction_stub).run!
        end
      end

      context 'when the transaction type is agent' do
        let(:transaction_stub) { build_stubbed(:postpaid_transaction_with_bill, :partner_bukopin, :agent) }

        before do
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_balance_mitra_bukopin, 19911500)
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_threshold_mitra_bukopin, 2000000)
        end

        it 'hit the metric correctly' do
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(transaction_stub).run!
        end
      end

      context 'when the transaction type is collecting agent' do
        let(:transaction_stub) { build_stubbed(:postpaid_transaction_with_bill, :partner_bukopin, :collecting_agent) }

        before do
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_balance_bukaconnect_bukopin, 29911500)
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_threshold_bukaconnect_bukopin, 3000000)
        end

        it 'hit the metric correctly' do
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(transaction_stub).run!
        end
      end
    end

    context 'when the partner is tektaya' do
      context 'when the transaction type is normal' do
        let(:transaction_stub) { build_stubbed(:postpaid_transaction_with_bill, :partner_tektaya) }

        before do
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_balance_tektaya, 9911500)
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_threshold_tektaya, 1000000)
        end

        it 'hit the metric correctly' do
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(transaction_stub).run!
        end
      end

      context 'when the transaction type is agent' do
        let(:transaction_stub) { build_stubbed(:postpaid_transaction_with_bill, :partner_tektaya, :agent) }

        before do
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_balance_mitra_tektaya, 19911500)
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_threshold_mitra_tektaya, 2000000)
        end

        it 'hit the metric correctly' do
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(transaction_stub).run!
        end
      end

      context 'when the transaction type is collecting agent' do
        let(:transaction_stub) { build_stubbed(:postpaid_transaction_with_bill, :partner_tektaya, :collecting_agent) }

        before do
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_balance_bukaconnect_tektaya, 29911500)
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_threshold_bukaconnect_tektaya, 3000000)
        end

        it 'hit the metric correctly' do
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(transaction_stub).run!
        end
      end
    end

    context 'when the partner is tektaya_bukaconnect' do
      context 'when the transaction type is normal' do
        let(:transaction_stub) { build_stubbed(:postpaid_transaction_with_bill, :partner_tektaya_bukaconnect) }

        before do
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_balance_tektaya_bukaconnect, 9911500)
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_threshold_tektaya_bukaconnect, 1000000)
        end

        it 'hit the metric correctly' do
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(transaction_stub).run!
        end
      end

      context 'when the transaction type is agent' do
        let(:transaction_stub) { build_stubbed(:postpaid_transaction_with_bill, :partner_tektaya_bukaconnect, :agent) }

        before do
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_balance_mitra_tektaya_bukaconnect, 19911500)
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_threshold_mitra_tektaya_bukaconnect, 2000000)
        end

        it 'hit the metric correctly' do
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(transaction_stub).run!
        end
      end

      context 'when the transaction type is collecting agent' do
        let(:transaction_stub) { build_stubbed(:postpaid_transaction_with_bill, :partner_tektaya_bukaconnect, :collecting_agent) }

        before do
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_balance_bukaconnect_tektaya_bukaconnect, 29911500)
          expect(Observer).to receive(:gauge).with(:postpaid_electricity_postpaid_threshold_bukaconnect_tektaya_bukaconnect, 3000000)
        end

        it 'hit the metric correctly' do
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(transaction_stub).run!
        end
      end
    end
  end
end
