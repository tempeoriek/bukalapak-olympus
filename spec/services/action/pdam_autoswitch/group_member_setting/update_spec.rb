require "rails_helper"

RSpec.describe Action::PdamAutoswitch::GroupMemberSetting::Update, type: :model do
  let(:params) {
    {
      threshold_value: 90,
      threshold_min_trx: 10,
      threshold_period_in_seconds: 45,
      threshold_type: 'refund_rate',
      threshold_state: 'active'
    }
  }

  subject { described_class.new(params) }

  describe '#run!' do
    let(:pdam_autoswitch_group_member_setting) { create(:pdam_autoswitch_group_member_setting) }

    context 'when autoswitch group member setting found' do
      before do
        allow(PdamAutoswitchGroupMemberSetting).to receive(:find_by_id).and_return pdam_autoswitch_group_member_setting
      end

      it 'changes the fields' do
        result = subject.run!
        expect(result.autoswitch_group_member_id).to eq(pdam_autoswitch_group_member_setting.autoswitch_group_member_id)
        expect(result.threshold_value).to eq(90)
        expect(result.threshold_min_trx).to eq(10)
        expect(result.threshold_period_in_seconds).to eq(45)
        expect(result.threshold_type).to eq('refund_rate')
        expect(result.threshold_state).to eq('active')
      end
    end

    context 'when autoswitch group member setting not found' do
      before do
        allow(PdamAutoswitchGroupMemberSetting).to receive(:find_by_id).and_return nil
      end

      it 'raises autoswitch group member setting not found' do
        expect{subject.run!}.to raise_error ::Exceptions::AutoswitchGroupMemberSettingNotFound
      end
    end
  end
end
