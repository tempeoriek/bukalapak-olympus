require 'rails_helper'

RSpec.describe Client, type: :model do
  describe '.name' do
    context 'has platform version' do
      let(:application_name) { 'bukalapak android apps new' }
      let(:version) {'4411211'}

      subject { described_class.new(application_name, version) }

      it 'return name with platform version' do
        expect(subject.name).to eq "android_app/#{version}"
      end
    end

    context 'doesnt have platform version' do
      let(:application_name) { 'bukalapak mobile web new' }
      let(:version) {''}

      subject { described_class.new(application_name, version) }

      it 'return name without platform version' do
        expect(subject.name).to eq 'mobile_web'
      end
    end
  end
end
