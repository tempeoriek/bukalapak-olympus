require "rails_helper"

RSpec.describe Action::PdamAutoswitch::Mechanism::Record, type: :model do
  let(:processed_count_setting) { build_stubbed(:pdam_autoswitch_group_member_setting, threshold_type: 'processed_count', threshold_value: 30, threshold_min_trx: 5, threshold_period_in_seconds: 15, threshold_state: 'active') }
  let(:refund_rate_setting) { build_stubbed(:pdam_autoswitch_group_member_setting, threshold_type: 'refund_rate', threshold_value: 50, threshold_min_trx: 5, threshold_period_in_seconds: 15, threshold_state: 'active') }

  let(:settings) {
    relation = PdamAutoswitchGroupMemberSetting.all
    relation.stub(:records).and_return([processed_count_setting, refund_rate_setting])
    relation
  }

  let(:now) { Time.now }
  let(:member_dji) { build_stubbed(:pdam_autoswitch_group_member, id: 1, operator: build_stubbed(:pdam_operator, :dji), settings: settings) }
  let(:member_sepulsa) { build_stubbed(:pdam_autoswitch_group_member, id: 2, operator: build_stubbed(:pdam_operator, :sepulsa), settings: settings) }

  let(:one_members) {
    relation = PdamAutoswitchGroupMember.all
    relation.stub(:records).and_return([member_dji])
    relation
  }
  let(:two_members) {
    relation = PdamAutoswitchGroupMember.all
    relation.stub(:records).and_return([member_dji, member_sepulsa])
    relation
  }

  let(:status) { :failed }
  let(:params) {
    {
      operator_id: 1,
      action: 'inquiry',
      status: status,
    }
  }
  subject { described_class.new(params) }

  before do
    allow(::Toggle::PdamAutoswitch)
      .to receive(:active?)
      .and_return(true)
  end

  describe 'O2OVPE-844: #run!' do
    context 'when can autoswitch' do
      context 'when no members in group' do
        before do
          allow(PdamAutoswitchGroupMember).to receive(:where).and_return(PdamAutoswitchGroupMember.none)
        end

        it 'returns noop' do
          expect(subject.run!).to eq(:noop)
        end
      end

      context 'when one active member in group with no settings' do
        let(:settings) { PdamAutoswitchGroupMemberSetting.none }
        before do
          allow(PdamAutoswitchGroupMember).to receive(:where).and_return(one_members)
        end

        let(:params) {
          {
            operator_id: one_members.first.operator_id,
            action: 'inquiry',
            status: :failed,
          }
        }

        it 'returns noop' do
          expect(subject.run!).to eq(:noop)
        end
      end

      context 'when one active member in group with two settings' do
        before do
          allow(PdamAutoswitchGroupMember).to receive(:where).and_return(one_members)
          allow(Time).to receive(:now).and_return(now)
          allow(RedisOlympus).to receive(:eval).with(
            Action::PdamAutoswitch::Mechanism::Record::LUA_SCRIPT,
            keys: ["pdam_autoswitch:group_member:1", "group_member_setting:1:processed_count:"],
            argv:[now.to_i, 15, 1],
          ).and_return([now.to_i, 100, 100])
        end

        let(:params) {
          {
            operator_id: one_members.first.operator_id,
            action: 'inquiry',
            status: :failed,
          }
        }

        it 'returns noop' do
          expect(subject.run!).to eq(:unavailable)
        end
      end

      context 'when two active members in group with two settings' do
        before do
          allow(PdamAutoswitchGroupMember).to receive_message_chain(:where, :preload).and_return(two_members)
          allow(Time).to receive(:now).and_return(now)
          allow(RedisOlympus).to receive(:eval).with(
            Action::PdamAutoswitch::Mechanism::Record::LUA_SCRIPT,
            keys: ["pdam_autoswitch:group_member:1", "group_member_setting:1:processed_count:"],
            argv:[now.to_i, 15, 1],
          ).and_return([now.to_i, 100, 100])
          allow(PdamAutoswitchGroupMember).to receive_message_chain(:where, :where, :not, :order).and_return(two_members)
          allow(member_dji).to receive(:update!).with(state: 'inactive').and_return(true)
          allow(member_sepulsa).to receive(:save!).and_return(true)
        end

        let(:params) {
          {
            operator_id: two_members.first.operator_id,
            action: 'inquiry',
            status: :failed,
          }
        }

        it 'returns switched' do
          expect(RedisOlympus).to receive(:set).with("pdam_autoswitch:switchback:#{member_dji.autoswitch_group_id}", true, ex: 60.minutes, nx: true).and_return(true)
          expect(Observer).to receive(:counter).with(
                                                      :pdam_auto_switch,
                                                      1,
                                                      {
                                                        :autoswitch_group_id=>anything,
                                                        :new_partner=>anything,
                                                        :old_partner=>anything,
                                                        :threshold_type=>"processed_count"
                                                      }
                                                    ).and_return(true)
          expect(Logger2).to receive(:error).and_return(true)
          expect(subject.run!).to eq(:switched)
        end
      end
    end
  end
end
