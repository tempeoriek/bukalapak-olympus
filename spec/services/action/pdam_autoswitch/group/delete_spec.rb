require "rails_helper"

RSpec.describe Action::PdamAutoswitch::Group::Delete, type: :model do
  let(:params) {
    {
      id: 1
    }
  }
  subject { described_class.new(params) }

  describe '#run!' do
    let(:pdam_autoswitch_group) { create(:pdam_autoswitch_group) }

    context 'when autoswitch group found' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return pdam_autoswitch_group
      end

      it 'changes the state' do
        expect{subject.run!}.to change(pdam_autoswitch_group, :state).to 'deleted'
      end
    end

    context 'when autoswitch group not found' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return nil
      end

      it 'raises autoswitch group not found' do
        expect{subject.run!}.to raise_error ::Exceptions::AutoswitchGroupNotFound
      end
    end
  end
end
