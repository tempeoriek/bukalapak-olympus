require "rails_helper"

RSpec.describe Action::PdamAutoswitch::Group::Create, type: :model do
  subject { described_class.new(params) }

  describe '#run!' do
    let(:pdam_autoswitch_group) { create(:pdam_autoswitch_group) }
    let(:params) {
      {
        name: 'Test 1',
        state: 'inactive'
      }
    }

    context 'when given required params' do
      before do
        allow(PdamAutoswitchGroup).to receive_message_chain(:where, :not_deleted, :first).and_return nil
      end

      it 'creates autoswitch group' do
        result = subject.run!
        expect(result).to be_kind_of(PdamAutoswitchGroup)
        expect(result.name).to eq('Test 1')
        expect(result.state).to eq('inactive')
      end
    end

    context 'when group with same name is found' do
      before do
        allow(PdamAutoswitchGroup).to receive_message_chain(:where, :not_deleted, :first).and_return pdam_autoswitch_group
      end

      it 'raises duplicate autoswitch group error' do
        expect{subject.run!}.to raise_error ::Exceptions::DuplicateAutoswitchGroup
      end
    end
  end
end
