require "rails_helper"

RSpec.describe Action::PdamAutoswitch::GroupMemberSetting::List, type: :model do
  let(:params) {
    {
      member_id: 1
    }
  }

  subject { described_class.new(params) }

  describe '#run!' do
    context 'when param given' do
      let (:setting_list) { [build_stubbed(:pdam_autoswitch_group_member_setting)] }

      before do
        allow(PdamAutoswitchGroupMemberSetting).to receive(:where).and_return setting_list
      end

      it 'calls where query' do
        result = subject.run!
        expect(result).to eq(setting_list)
      end
    end
  end
end
