require "rails_helper"

RSpec.describe Action::PdamAutoswitch::Group::Update, type: :model do
  let(:params) {
    {
      id: 1,
      name: 'Haha test update'
    }
  }
  subject { described_class.new(params) }

  describe '#run!' do
    let(:pdam_autoswitch_group) { create(:pdam_autoswitch_group) }

    context 'when autoswitch group with given name is not found' do
      before do
        allow(PdamAutoswitchGroup).to receive_message_chain(:where, :where, :not, :not_deleted, :first).and_return nil
      end

      context 'when autoswitch group found' do
        before do
          allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return pdam_autoswitch_group
        end

        it 'changes the name' do
          expect(subject.run!.name).to eq 'Haha test update'
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

    context 'when autoswitch group with given name is found' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return pdam_autoswitch_group
        allow(PdamAutoswitchGroup).to receive_message_chain(:where, :where, :not, :not_deleted, :first).and_return pdam_autoswitch_group
      end

      it 'raises autoswitch group duplicate error' do
        expect{subject.run!}.to raise_error ::Exceptions::DuplicateAutoswitchGroup
      end
    end
  end
end
