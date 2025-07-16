# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::Tektaya::Helpers::BuyerType, type: :model do
  let(:dummy_class) {
    Class.new do
      include Channel::Tektaya::Helpers::BuyerType
    end
  }

  describe '#retrieve_buyer_type_config' do
    subject { dummy_class.new.retrieve_buyer_type_config(buyer_type) }

    context 'with mitra buyer type' do
      let(:buyer_type) { Channel::Tektaya::Helpers::Constants::MITRA_BUYER_TYPE }
      let(:expected_result) {
        {
          buyer_type: Channel::Tektaya::Helpers::Constants::MITRA_BUYER_TYPE,
          user_id: Channel::Tektaya::Helpers::Constants::BMI_USER_ID,
          password: Channel::Tektaya::Helpers::Constants::BMI_PASSWORD,
          bit62: Channel::Tektaya::Helpers::Constants::BMI_BIT62
        }
      }

      it 'returns expected results' do
        expect(subject).to eq expected_result
      end
    end

    context 'with normal buyer type' do
      let(:buyer_type) { Channel::Tektaya::Helpers::Constants::NORMAL_BUYER_TYPE }
      let(:expected_result) {
        {
          buyer_type: Channel::Tektaya::Helpers::Constants::NORMAL_BUYER_TYPE,
          user_id: Channel::Tektaya::Helpers::Constants::BL_USER_ID,
          password: Channel::Tektaya::Helpers::Constants::BL_PASSWORD,
          bit62: Channel::Tektaya::Helpers::Constants::BL_BIT62
        }
      }

      it 'returns expected results' do
        expect(subject).to eq expected_result
      end
    end

    context 'with bukaconnect buyer type' do
      let(:buyer_type) { Channel::Tektaya::Helpers::Constants::BUKACONNECT_BUYER_TYPE }
      let(:expected_result) {
        {
          buyer_type: Channel::Tektaya::Helpers::Constants::BUKACONNECT_BUYER_TYPE,
          user_id: Channel::Tektaya::Helpers::Constants::BMI_BUKACONNECT_USER_ID,
          password: Channel::Tektaya::Helpers::Constants::BMI_BUKACONNECT_PASSWORD,
          bit62: Channel::Tektaya::Helpers::Constants::BMI_BUKACONNECT_BIT62
        }
      }

      it 'returns expected results' do
        expect(subject).to eq expected_result
      end
    end

    context 'with uninitialized buyer type' do
      let(:buyer_type) { 'somebuyertype' }
      let(:expected_result) { nil }

      it 'returns expected results' do
        expect(subject).to eq expected_result
      end
    end
  end

  describe '#determine_redis_key' do
    subject { dummy_class.new.determine_redis_key(buyer_type) }

    context 'with mitra buyer type' do
      let(:buyer_type) { Channel::Tektaya::Helpers::Constants::MITRA_BUYER_TYPE }
      let(:expected_result) { Channel::Tektaya::Helpers::Constants::BMI_SESSION_KEY }

      it 'returns expected results' do
        expect(subject).to eq expected_result
      end
    end

    context 'with normal buyer type' do
      let(:buyer_type) { Channel::Tektaya::Helpers::Constants::NORMAL_BUYER_TYPE }
      let(:expected_result) { Channel::Tektaya::Helpers::Constants::BL_SESSION_KEY }

      it 'returns expected results' do
        expect(subject).to eq expected_result
      end
    end

    context 'with normal buyer type' do
      let(:buyer_type) { Channel::Tektaya::Helpers::Constants::BUKACONNECT_BUYER_TYPE }
      let(:expected_result) { Channel::Tektaya::Helpers::Constants::BMI_BUKACONNECT_SESSION_KEY }

      it 'returns expected results' do
        expect(subject).to eq expected_result
      end
    end

    context 'with uninitialized buyer type' do
      let(:buyer_type) { 'somebuyertype' }

      it 'returns expected results' do
        expect { subject }.to raise_error(::Exceptions::PartnerIssue, 'Cannot determine Tektaya session key')
      end
    end
  end
end
