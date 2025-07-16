require "rails_helper"

RSpec.describe Action::PdamAutoswitch::GroupMember::Status, type: :model do
  let(:params) {
    {
      id: 1,
      state: 'inactive'
    }
  }
  subject { described_class.new(params) }

  describe '#run!' do
    let(:pdam_autoswitch_group_member) { create(:pdam_autoswitch_group_member) }

    context 'when autoswitch group found' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return pdam_autoswitch_group_member
      end

      it 'changes the state' do
        expect(subject.run!.state).to eq 'inactive'
      end
    end

    context 'when autoswitch group not found' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return nil
      end

      it 'raises autoswitch group not found' do
        expect{subject.run!}.to raise_error ::Exceptions::AutoswitchGroupMemberNotFound
      end
    end
  end
end
