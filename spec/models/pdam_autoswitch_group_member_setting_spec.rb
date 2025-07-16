require 'rails_helper'
include Postpaid::Constant

RSpec.describe PdamAutoswitchGroupMemberSetting, type: :model do
  subject { build_stubbed(:pdam_autoswitch_group_member_setting) }

  describe '.is_type_valid' do
    context 'returns true' do
      it { expect(PdamAutoswitchGroupMemberSetting.is_type_valid('processed_count')).to eq true }
    end

    context 'returns false' do
      it { expect(PdamAutoswitchGroupMemberSetting.is_type_valid('processed')).to eq false }
    end
  end

  describe '.is_state_valid' do
    context 'returns true' do
      it { expect(PdamAutoswitchGroupMemberSetting.is_state_valid('inactive')).to eq true }
    end

    context 'returns false' do
      it { expect(PdamAutoswitchGroupMemberSetting.is_state_valid('not_active')).to eq false }
    end
  end
end
