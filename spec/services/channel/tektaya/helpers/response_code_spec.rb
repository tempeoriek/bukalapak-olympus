require 'rails_helper'

RSpec.describe Channel::Tektaya::Helpers::ResponseCode, type: :model do
  let(:dummy_class) {
    Class.new do
      include Channel::Tektaya::Helpers::ResponseCode
    end
  }

  describe '#get_status_from_response_code' do
    context 'when the rc is success' do
      success_response_codes = ['00']

      success_response_codes.each do |rc|
        it "returns success for rc #{rc}" do
          expect(dummy_class.new.get_status_from_response_code(rc)).to eq :success
        end
      end
    end

    context 'when the rc is pending' do
      pending_response_codes = ['16', '68']

      pending_response_codes.each do |rc|
        it "returns pending for rc #{rc}" do
          expect(dummy_class.new.get_status_from_response_code(rc)).to eq :pending
        end
      end
    end

    context 'when the rc is failed' do
      failed_response_codes = [
        '01', '02', '04', '05', '09',
        '10', '11', '12', '13', '14',
        '15', '17', '33', '41', '42',
        '47', '51', '54', '55', '63',
        '67', '72', '74', '77', '88',
        '89', '91', '92', '94', '96',
        '97', '99'
      ] 

      failed_response_codes.each do |rc|
        it "returns failed for rc #{rc}" do
          expect(dummy_class.new.get_status_from_response_code(rc)).to eq :failed
        end
      end
    end

    context 'when the rc is unknown' do
      let(:rc) { '12345678' }

      it 'returns nil' do
        expect(dummy_class.new.get_status_from_response_code(rc)).to be_nil
      end
    end
  end
end
