# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Action::PdamAutoswitch::Mechanism::Switchback, type: :model do
  let(:autoswitch_group) { build_stubbed(:pdam_autoswitch_group) }
  let(:autoswitch_member_a) { build_stubbed(:pdam_autoswitch_group_member, id: 1) }
  let(:autoswitch_member_b) { build_stubbed(:pdam_autoswitch_group_member, id: 2) }
  let(:subject) { described_class.new.perform }

  before do
    allow(PdamAutoswitchGroup).to receive(:all).and_return([autoswitch_group])
  end

  describe 'O2OVPE-2704: #perform' do
    context 'when switchback key exists' do
      before do
        allow(RedisOlympus).to receive(:exists?).with("pdam_autoswitch:switchback:#{autoswitch_group.id}").and_return(true)
      end

      it 'returns 0 switched result' do
        expect(Observer).not_to receive(:counter)
        expect(subject).to eq(0)
      end
    end

    context 'when there is no need to switch' do
      before do
        allow(RedisOlympus).to receive(:exists?).with("pdam_autoswitch:switchback:#{autoswitch_group.id}").and_return(false)
        members_chain = double('members_chain')
        allow(autoswitch_group).to receive_message_chain(:members, :where).and_return(members_chain)
        allow(members_chain).to receive_message_chain(:not, :order, :first).and_return(autoswitch_member_a)
        allow(members_chain).to receive(:first).and_return(autoswitch_member_a)
      end

      it 'returns 0 switched result' do
        expect(Observer).not_to receive(:counter)
        expect(subject).to eq(0)
      end
    end

    context 'when switching to the highest priority member' do
      before do
        allow(RedisOlympus).to receive(:exists?).with("pdam_autoswitch:switchback:#{autoswitch_group.id}").and_return(false)
        members_chain = double('members_chain')
        allow(autoswitch_group).to receive_message_chain(:members, :where).and_return(members_chain)
        allow(members_chain).to receive_message_chain(:not, :order, :first).and_return(autoswitch_member_a)
        allow(members_chain).to receive(:first).and_return(autoswitch_member_b)
      end

      it 'switches to the highest priority partner and returns 1 switched result' do
        expect(autoswitch_member_a).to receive(:update!).and_return(true)
        expect(autoswitch_member_b).to receive(:update!).and_return(true)
        expect(RedisOlympus).to receive(:del).with("pdam_autoswitch:group_member:#{autoswitch_member_b.id}").and_return(true)
        expect(subject).to eq(1)
      end
    end
  end
end
