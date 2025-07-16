require "rails_helper"

RSpec.describe Action::ElectricityAutoswitch::Mechanism::Record, type: :model do
  let(:now) { Time.now }
  
  let(:partner_sepulsa) { build(:electricity_postpaid_partner, :sepulsa, :active, id: 1) }
  let(:partner_bukopin) { build(:electricity_postpaid_partner, :bukopin, id: 2) }

  let(:one_item_config) {
    [
      {
        priority: 1,
        partner_name: 'sepulsa',
        status: 'active',
        thresholds: []
      }
    ]
  }
  let(:one_item_config_with_two_thresholds) {
    [
      {
        priority: 1,
        partner_name: 'sepulsa',
        status: 'active',
        thresholds: [
          {
            type: "processed_count",
            value: 10,
            min_trx: 1,
            period_in_seconds: 60,
            status: "active"
          },
          {
            type: "refund_rate",
            value: 10,
            min_trx: 1,
            period_in_seconds: 60,
            status: "active"
          },
        ]
      }
    ]
  }

  let(:status) { :failed }
  let(:params) {
    {
      action: 'inquiry',
      status: status,
    }
  }
  subject { described_class.new(params) }

  describe 'O2OVPE-1674: #run!' do
    context 'when can autoswitch' do
      context 'when no item (partner) in config' do
        before do
          allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
          allow(Config::ElectricityPostpaidAutoswitch).to receive_message_chain(:config, :fetch).and_return([])
          allow(Config::AutoswitchSwitchbackDuration).to receive(:get_duration_by_day).with(60).and_return(60.minutes)
        end

        it 'returns noop' do
          expect(subject.run!).to eq(:noop)
        end
      end

      context 'when one active item (partner) in config with no threshold setting' do
        let(:settings) { [] }
        before do
          allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
          allow(Config::ElectricityPostpaidAutoswitch).to receive_message_chain(:config, :fetch).and_return(one_item_config)
          allow(ElectricityPostpaidPartner).to receive(:find_by).and_return(partner_sepulsa)
        end

        let(:params) {
          {
            action: 'inquiry',
            status: :failed,
          }
        }

        it 'returns noop' do
          expect(subject.run!).to eq(:noop)
        end
      end

      context 'when only one partner available' do
        before do
          allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
          allow(Config::ElectricityPostpaidAutoswitch).to receive_message_chain(:config, :fetch).and_return(one_item_config_with_two_thresholds)
          allow(ElectricityPostpaidPartner).to receive_message_chain(:where, :order, :to_a).and_return([partner_sepulsa])
          allow(ElectricityPostpaidPartner).to receive(:find_by).and_return(partner_sepulsa)
          allow(Time).to receive(:now).and_return(now)
          allow(RedisOlympus).to receive(:eval).with(
            Action::ElectricityAutoswitch::Mechanism::Record::LUA_SCRIPT, 
            keys: ["electricity_autoswitch:partner:1", "threshold:processed_count"],
            argv:[now.to_i, 60, 1], 
          ).and_return([now.to_i, 100, 100])
        end

        let(:params) {
          {
            action: 'inquiry',
            status: :failed,
          }
        }

        it 'returns unavailable' do
          expect(subject.run!).to eq(:unavailable)
        end
      end

      context 'when threshold setting and multiple partner available' do
        before do
          allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
          allow(Config::ElectricityPostpaidAutoswitch).to receive_message_chain(:config, :fetch).and_return(one_item_config_with_two_thresholds)
          allow(ElectricityPostpaidPartner).to receive_message_chain(:where, :order, :to_a).and_return([partner_sepulsa, partner_bukopin])
          allow(ElectricityPostpaidPartner).to receive(:find_by).and_return(partner_sepulsa)
          allow(Time).to receive(:now).and_return(now)
          allow(RedisOlympus).to receive(:eval).with(
            Action::ElectricityAutoswitch::Mechanism::Record::LUA_SCRIPT, 
            keys: ["electricity_autoswitch:partner:1", "threshold:processed_count"],
            argv:[now.to_i, 60, 1], 
          ).and_return([now.to_i, 100, 100])
          allow(partner_sepulsa).to receive(:update!).with(state: 'inactive').and_return(true)
          allow(partner_bukopin).to receive(:save!).and_return(true)
        end

        let(:params) {
          {
            action: 'inquiry',
            status: :failed,
          }
        }

        it 'returns switched' do
          metric_tags = {
            old_partner: partner_sepulsa.name,
            new_partner: partner_bukopin.name,
            threshold_type: 'processed_count'
          }
          expect(Observer).to receive(:counter).with(Observer::Metric::TAGLIS_AUTO_SWITCH, 1, metric_tags).once
          expect(RedisOlympus).to receive(:set).with(
            "electricity_autoswitch:switchback",
            anything,
            {:ex => 60.minutes, :nx => true}
          )
          expect(subject.run!).to eq(:switched)
        end
      end

      context 'when switching to first priority partner' do
        before do
          allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
          allow(Config::ElectricityPostpaidAutoswitch).to receive_message_chain(:config, :fetch).and_return(one_item_config_with_two_thresholds)
          allow(ElectricityPostpaidPartner).to receive_message_chain(:where, :order, :to_a).and_return([partner_bukopin, partner_sepulsa])
          allow(ElectricityPostpaidPartner).to receive(:find_by).and_return(partner_sepulsa)
          allow(Time).to receive(:now).and_return(now)
          allow(RedisOlympus).to receive(:eval).with(
            Action::ElectricityAutoswitch::Mechanism::Record::LUA_SCRIPT, 
            keys: ["electricity_autoswitch:partner:1", "threshold:processed_count"],
            argv:[now.to_i, 60, 1], 
          ).and_return([now.to_i, 100, 100])
          allow(partner_sepulsa).to receive(:update!).with(state: 'inactive').and_return(true)
          allow(partner_bukopin).to receive(:save!).and_return(true)
        end

        let(:params) {
          {
            action: 'inquiry',
            status: :failed,
          }
        }

        it 'returns switched' do
          metric_tags = {
            old_partner: partner_sepulsa.name,
            new_partner: partner_bukopin.name,
            threshold_type: 'processed_count'
          }
          expect(Observer).to receive(:counter).with(Observer::Metric::TAGLIS_AUTO_SWITCH, 1, metric_tags).once
          expect(RedisOlympus).not_to receive(:set)
          expect(subject.run!).to eq(:switched)
        end
      end
    end
  end
end
