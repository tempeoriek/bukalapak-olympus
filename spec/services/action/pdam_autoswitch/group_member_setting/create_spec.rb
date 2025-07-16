require "rails_helper"

RSpec.describe Action::PdamAutoswitch::GroupMemberSetting::Create, type: :model do
  let(:params) {
    {
      member_id: 1,
      threshold_value: 30,
      threshold_min_trx: 1,
      threshold_period_in_seconds: 15,
      threshold_type: 'processed_count',
      threshold_state: 'inactive'
    }
  }

  subject { described_class.new(params) }

  describe '#run!' do
    context 'when given required params' do
      before do
        allow(PdamAutoswitchGroupMember).to receive(:find_by_id).and_return build_stubbed(:pdam_autoswitch_group_member)
      end

      it 'creates autoswitch group member setting' do
        result = subject.run!
        expect(result).to be_kind_of(PdamAutoswitchGroupMemberSetting)
        expect(result.autoswitch_group_member_id).to eq(1)
        expect(result.threshold_value).to eq(30)
        expect(result.threshold_min_trx).to eq(1)
        expect(result.threshold_period_in_seconds).to eq(15)
        expect(result.threshold_type).to eq('processed_count')
        expect(result.threshold_state).to eq('inactive')
      end
    end

    context 'when member not found' do
      before do
        allow(PdamAutoswitchGroupMember).to receive(:find_by_id).and_return nil
      end

      it 'raises autoswitch group member not found' do
        expect { subject.run! }.to raise_error ::Exceptions::AutoswitchGroupMemberNotFound
      end
    end
  end
end
