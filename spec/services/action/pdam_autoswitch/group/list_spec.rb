require "rails_helper"

RSpec.describe Action::PdamAutoswitch::Group::List, type: :model do
  subject { described_class.new(params) }

  describe '#run!' do
    context 'when name param given' do
      let(:params) {
        {
          name: 'test',
          offset: 10,
          limit: 10
        }
      }

      it 'calls where query using name' do
        expect(PdamAutoswitchGroup).to receive_message_chain(:where, :not_deleted, :order)
        subject.run!
      end
    end

    context 'when name param not given' do
      let(:params) {
        {
          offset: 10,
          limit: 10
        }
      }

      before do
        allow(PdamAutoswitchGroup).to receive(:find_by_id).and_return nil
      end

      it 'not calls where query using name' do
        expect(PdamAutoswitchGroup).to receive_message_chain(:not_deleted, :order)
        subject.run!
      end
    end
  end
end
