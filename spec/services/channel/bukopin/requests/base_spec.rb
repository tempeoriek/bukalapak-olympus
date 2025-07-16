require "rails_helper"
require 'support/electricity_mocks'
include PostpaidTransactionUtility

RSpec.describe Channel::Bukopin::ElectricityPostpaid::Requests::Base, type: :helper do
  include_context "electricity_mocks"

  let(:constants) { Channel::Bukopin::ElectricityPostpaid::Constants }

  def test_network(method, network_code, request_response)
    allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Network)
      .to receive(:run!)
      .and_return(request_response)

    expect(Channel::Bukopin::ElectricityPostpaid::Requests::Network)
      .to receive(:new)
      .with(network_code, NORMAL_BUYER_TYPE)
      .and_return(Channel::Bukopin::ElectricityPostpaid::Requests::Network.new(network_code, NORMAL_BUYER_TYPE))

    expect{ subject.send(method) }.not_to raise_error
  end

  def test_network_agent(method, network_code, request_response)
    allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
    expect(Channel::Bukopin::ElectricityPostpaid::Requests::Network)
      .to receive(:new)
      .with(network_code, AGENT_BUYER_TYPE)
      .and_call_original
    allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Network)
      .to receive(:run!)
      .and_return(request_response)

    expect{ subject.send(method) }.not_to raise_error
  end

  describe 'Normal Buyer Type' do
    subject { Channel::Bukopin::ElectricityPostpaid::Requests::Base.new(NORMAL_BUYER_TYPE) }

    before do
      allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
    end

    describe '.sign_on' do
      context 'when sign_on succeed' do
        it 'does not raise error' do
          test_network(:sign_on, constants::NetworkCodes::SIGN_ON, bukopin_network_request_response)
        end
      end
    end

    describe '.sign_off' do
      context 'when sign_off succeed' do
        it 'does not raise error' do
          test_network(:sign_off, constants::NetworkCodes::SIGN_OFF, bukopin_network_request_response)
        end
      end
    end

    describe '.echo' do
      context 'when echo succeed' do
        it 'does not raise error' do
          test_network(:echo, constants::NetworkCodes::ECHO_TEST, bukopin_network_request_response)
        end
      end
    end

    describe '.get_key' do
      context 'when get_key succeed' do
        it 'does not raise error and sets the right key' do
          test_network(:get_key, constants::NetworkCodes::GET_KEY, bukopin_network_request_response)

          # assert BUKOPIN_PRIVATE_KEY env
          expect(Channel::Config::BUKOPIN_PRIVATE_KEY).to eq('D97BF4016353DC783E3424BB3777F2BF0B221C762F15EF38')
          # test the bukopin key in db
          expect(Keystore.get(constants::BUKOPIN_ENCRYPT_KEY)).to eq("34a3160f6b9f44d1c261e98de0390baf056098f706a92d16")
        end
      end
    end

    describe '.flush_key' do
      context 'when flushing_key' do
        it 'sets the key to nil' do
          expect{ subject.flush_key }.not_to raise_error
          expect(Keystore.get(constants::BUKOPIN_ENCRYPT_KEY)).to eq(nil)
        end
      end
    end
  end
  describe 'Agent Buyer Type' do
    subject { Channel::Bukopin::ElectricityPostpaid::Requests::Base.new(AGENT_BUYER_TYPE) }

    before do
      allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
    end

    describe '.sign_on' do
      context 'when sign_on succeed' do
        it 'does not raise error' do
          test_network_agent(:sign_on, constants::NetworkCodes::SIGN_ON, bukopin_network_request_response)
        end
      end
    end

    describe '.sign_off' do
      context 'when sign_off succeed' do
        it 'does not raise error' do
          test_network_agent(:sign_off, constants::NetworkCodes::SIGN_OFF, bukopin_network_request_response)
        end
      end
    end

    describe '.echo' do
      context 'when echo succeed' do
        it 'does not raise error' do
          test_network_agent(:echo, constants::NetworkCodes::ECHO_TEST, bukopin_network_request_response)
        end
      end
    end

    describe '.get_key' do
      context 'when get_key succeed' do
        it 'does not raise error and sets the right key' do
          test_network_agent(:get_key, constants::NetworkCodes::GET_KEY, bukopin_network_request_response)

          # assert BUKOPIN_PRIVATE_KEY env
          expect(Channel::Config::BUKOPIN_PRIVATE_KEY_BMI).to eq('707556970951292153602709466020752317373756576138')
          # test the bukopin key in db
          expect(Keystore.get(constants::BUKOPIN_ENCRYPT_KEY_BMI)).to eq("6d7f50f4d48fa038ab67199672b06a9dec751b3a5347ba63")
        end
      end
    end

    describe '.flush_key' do
      context 'when flushing_key' do
        it 'sets the key to nil' do
          expect(Keystore).to receive(:del)
            .with('bukopin_encript_key_bmi')
            .and_call_original
            .once
          expect{ subject.flush_key }.not_to raise_error
          expect(Keystore.get(constants::BUKOPIN_ENCRYPT_KEY_BMI)).to eq(nil)
        end
      end
    end
  end

end
