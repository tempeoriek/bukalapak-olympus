# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Action::ElectricityAutoswitch::Mechanism::Switchback, type: :model do
  let(:partner_sepulsa) { create(:electricity_postpaid_partner, :sepulsa, :active) }
  let(:partner_bukopin) { create(:electricity_postpaid_partner, :bukopin, :inactive) }
  let(:switchback) { described_class.new }

  before do
    allow(Config::ElectricityPostpaidAutoswitch).to receive(:config).and_return(config)
    allow(ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
  end

  describe 'O2OVPE-2703: #perform' do
    context 'when switchback key exists' do
      before do
        allow(RedisOlympus).to receive(:exists?).with('electricity_autoswitch:switchback').and_return(true)
      end

      it 'returns noop' do
        expect(switchback.perform).to eq(:noop)
      end
    end

    context 'when there is no need to switch' do
      before do
        allow(RedisOlympus).to receive(:exists?).with('electricity_autoswitch:switchback').and_return(false)
        allow(switchback).to receive(:should_switch_partner?).and_return(false)
      end

      it 'returns noop' do
        expect(switchback.perform).to eq(:noop)
      end
    end

    context 'when switching to the highest priority partner' do
      let(:config) do
        {
          config: [
            {
              priority: 1,
              partner_name: 'bukopin',
              status: 'active'
            },
            {
              priority: 2,
              partner_name: 'sepulsa',
              status: 'active'
            }
          ]
        }
      end

      before do
        allow(RedisOlympus).to receive(:exists?).with('electricity_autoswitch:switchback').and_return(false)
        allow(ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
        allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'bukopin').and_return(partner_bukopin)
      end

      it 'switches to the highest priority partner and returns switched' do
        expect(partner_sepulsa).to receive(:update!).with(state: 'inactive').and_return(true)
        expect(partner_bukopin).to receive(:update!).with(state: 'active').and_return(true)
        expect(RedisOlympus).to receive(:del).with("electricity_autoswitch:partner:#{partner_sepulsa.id}").and_return(true)
        expect(Observer).to receive(:counter).with(:postpaid_electricity_postpaid_auto_switch, 1, anything)
        expect(Logger2).to receive(:info)

        expect(switchback.perform).to eq(:switched)
      end
    end
  end

  describe 'O2OVPE-2703: #should_switch_partner?' do
    context 'when config is empty' do
      let(:config) { { config: [] } }

      it 'returns false' do
        expect(switchback.send(:should_switch_partner?)).to eq(false)
      end
    end

    context 'when the highest priority partner is already active' do
      let(:config) do
        {
          config: [
            {
              priority: 1,
              partner_name: 'sepulsa',
              status: 'active'
            }
          ]
        }
      end

      before do
        allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'sepulsa').and_return(partner_sepulsa)
      end

      it 'returns false' do
        expect(switchback.send(:should_switch_partner?)).to eq(false)
      end
    end

    context 'when the highest priority partner is not active' do
      let(:config) do
        {
          config: [
            {
              priority: 1,
              partner_name: 'bukopin',
              status: 'active'
            },
            {
              priority: 2,
              partner_name: 'sepulsa',
              status: 'active'
            }
          ]
        }
      end

      before do
        allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'bukopin').and_return(partner_bukopin)
      end

      it 'returns true' do
        expect(switchback.send(:should_switch_partner?)).to eq(true)
      end
    end

    context 'when current partner is nil' do
      let(:config) do
        {
          config: [
            {
              priority: 1,
              partner_name: 'bukopin',
              status: 'active'
            },
            {
              priority: 2,
              partner_name: 'sepulsa',
              status: 'active'
            }
          ]
        }
      end

      before do
        allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'bukopin').and_return(nil)
      end

      it 'returns false' do
        expect(switchback.send(:should_switch_partner?)).to eq(false)
      end
    end
  end
end
