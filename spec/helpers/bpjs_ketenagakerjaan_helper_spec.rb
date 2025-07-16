require 'rails_helper'

RSpec.describe BpjsKetenagakerjaanHelper, type: :model do
  describe '.mask_name' do
    context 'when name contains word with lengths more than 3' do
      let(:name) { 'Dennis Chan' }

      subject { BpjsKetenagakerjaanHelper.mask_name(name) }

      it 'should masks the third until second last characters of each word' do
        expect(subject).to eq 'De***s Ch*n'
      end
    end

    context 'when name contains word with lengths 3 or less' do
      let(:name) { 'Lim Ji Koo' }

      subject { BpjsKetenagakerjaanHelper.mask_name(name) }

      it 'should not masks words' do
        expect(subject).to eq 'Lim Ji Koo'
      end
    end
  end
end
