require 'rails_helper'

class DummyClass
  include PdamAutoswitchHelper
end

RSpec.describe PdamAutoswitchHelper, type: :model do
  let(:pdam_autoswitch_group) { build_stubbed(:pdam_autoswitch_group, :with_members) }
  let(:pdam_autoswitch_group_inactive) { build_stubbed(:pdam_autoswitch_group, :with_members, :inactive) }

  let(:pdam_operator) { build_stubbed(:pdam_operator) }

  describe '.select_active_operator_by_group_id' do
    let(:expected_positive_result) { 'testing_case' }

    context 'when group not found' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return nil
      end

      subject { DummyClass.new.select_active_operator_by_group_id(1) }

      it 'raises pdam autoswitch group not found' do
        expect{subject}.to raise_error ::Exceptions::AutoswitchGroupNotFound
      end
    end

    context 'when group inactive' do
      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return pdam_autoswitch_group_inactive
      end

      subject { DummyClass.new.select_active_operator_by_group_id(1) }

      it 'raises pdam autoswitch group not found' do
        expect{subject}.to raise_error ::Exceptions::AutoswitchGroupInactive
      end
    end

    context 'when group found' do
      let(:pdam_autoswitch_group_stored) { create(:pdam_autoswitch_group) }
      let(:active_operator_other) { create(:pdam_operator) }
      let(:inactive_operator) { create(:pdam_operator, :inactive) }
      let(:active_operator) { create(:pdam_operator) }

      before do
        active_member_with_inactive_operator = PdamAutoswitchGroupMember.create(autoswitch_group_id: pdam_autoswitch_group_stored.id, state: 'active', operator_id: inactive_operator.id)
        inactive_member_with_active_operator = PdamAutoswitchGroupMember.create(autoswitch_group_id: pdam_autoswitch_group_stored.id, state: 'inactive', operator_id: active_operator_other.id)
        inactive_member_with_inactive_operator = PdamAutoswitchGroupMember.create(autoswitch_group_id: pdam_autoswitch_group_stored.id, state: 'inactive', operator_id: inactive_operator.id)
        active_member_with_active_operator = PdamAutoswitchGroupMember.create(autoswitch_group_id: pdam_autoswitch_group_stored.id, state: 'active', operator_id: active_operator.id)
      end

      subject { DummyClass.new.select_active_operator_by_group_id(pdam_autoswitch_group_stored.id) }

      it 'returns desired pdam operator' do
        expect(subject).to be_kind_of(PdamOperator)
        expect(subject).to eq(active_operator)
      end
    end

    context 'when group deleted' do
      let(:deleted_pdam_autoswitch_group) { build_stubbed(:pdam_autoswitch_group, :deleted) }

      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return deleted_pdam_autoswitch_group
      end

      subject { DummyClass.new.select_active_operator_by_group_id(1) }

      it 'raises pdam autoswitch group not found' do
        expect{subject}.to raise_error ::Exceptions::AutoswitchGroupNotFound
      end
    end
  end
end
