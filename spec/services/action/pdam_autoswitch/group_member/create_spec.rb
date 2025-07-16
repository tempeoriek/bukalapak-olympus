require "rails_helper"

RSpec.describe Action::PdamAutoswitch::GroupMember::Create, type: :model do
  subject { described_class.new(params) }

  describe '#run!' do
    let(:pdam_autoswitch_group_member) { create(:pdam_autoswitch_group_member) }

    let(:params) {
      {
        group_id: 1,
        operator_id: 1,
        state: 'inactive'
      }
    }

    context 'when given required params' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return build_stubbed(:pdam_autoswitch_group)
        allow(PdamOperator).to receive(:find_by_id).and_return build_stubbed(:pdam_operator)
      end

      it 'creates autoswitch group member' do
        result = subject.run!
        expect(result).to be_kind_of(PdamAutoswitchGroupMember)
        expect(result.autoswitch_group_id).to eq(1)
        expect(result.state).to eq('inactive')
      end

      context 'when member is not registered' do
        before do
          allow(PdamAutoswitchGroupMember).to receive_message_chain(:where, :first).and_return nil
        end

        it 'creates autoswitch group member' do
          expect(PdamAutoswitchGroupMember).to receive(:create).and_call_original

          result = subject.run!
          expect(result).to be_kind_of(PdamAutoswitchGroupMember)
          expect(result.autoswitch_group_id).to eq(1)
          expect(result.state).to eq('inactive')
        end
      end

      context 'when member is registered but deleted' do
        let(:deleted_member) { create(:pdam_autoswitch_group_member, :deleted) }
        before do
          allow(PdamAutoswitchGroupMember).to receive_message_chain(:where, :first).and_return deleted_member
        end

        it 'revives autoswitch group member' do
          expect{subject.run!}.to change(deleted_member, :state).to 'inactive'
        end
      end

      context 'when member is registered and not deleted' do
        before do
          allow(PdamAutoswitchGroupMember).to receive_message_chain(:where, :first).and_return pdam_autoswitch_group_member
        end

        it 'raises duplicate autoswitch group member error' do
          expect{subject.run!}.to raise_error ::Exceptions::DuplicateAutoswitchGroupMember
        end
      end
    end

    context 'when group not found' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return nil
      end

      it 'raises autoswitch group not found' do
        expect{subject.run!}.to raise_error ::Exceptions::AutoswitchGroupNotFound
      end
    end

    context 'when operator not found' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return build_stubbed(:pdam_autoswitch_group)
        allow(PdamOperator).to receive(:find_by_id).and_return nil
      end

      it 'raises autoswitch group not found' do
        expect{subject.run!}.to raise_error ::Exceptions::InvalidPdamOperator
      end
    end
  end
end
