# frozen_string_literal: true

require 'rails_helper'

# this one assume that when migrating with new toggle
# it doesn't have a class method `toggle_name`
class ModelWithOldToggleClass < ::Toggle::Base
end

# this one assume that when migrating with new toggle
# it overrides the toggle_name
class ModelWithNewToggleClass < ::Toggle::Base
  def self.toggle_name
    'toggle/test'
  end
end

RSpec.describe ::Toggle::Base, type: :model do
  let(:toggle_name) { 'toggle/test' }

  describe '.toggle_name' do
    subject { toggle_class }

    context 'with new class' do
      let(:toggle_class) { ModelWithNewToggleClass.toggle_name }

      it { is_expected.to eq(toggle_name) }
    end

    context 'with old class' do
      let(:toggle_class) { ModelWithOldToggleClass.toggle_name }

      it { is_expected.to eq('olympus/model_with_old_toggle_class') }
    end
  end

  describe '.active?' do
    subject { ModelWithNewToggleClass.active? }

    context 'when toggle is on' do
      let(:neotoggle) { NeoClient::Toggle.new(active: true, id: toggle_name) }

      before { allow(NeoClient::Search).to receive(:toggle).and_return(neotoggle) }

      it { expect(subject).to eq(true) }
    end

    context 'when toggle is off' do
      let(:neotoggle) { NeoClient::Toggle.new(active: false, id: toggle_name) }

      before { allow(NeoClient::Search).to receive(:toggle).and_return(neotoggle) }

      it { expect(subject).to eq(false) }
    end

    context 'when neo raise an error' do
      let(:standard_error) { StandardError.new('neo is down bro') }
      let(:error_msg) { "Toggle '#{toggle_name}' encountered #{standard_error.class}: #{standard_error.message}. It will use false as default toggle state" }

      it do
        allow(NeoClient::Search).to receive(:toggle).and_raise(standard_error)
        allow(Rails.logger).to receive(:error).and_call_original
        expect(Rails.logger).to receive(:error).with(
          message: error_msg,
          tags: ['toggle', 'neo', toggle_name]
        )
        expect(subject).to eq(false)
      end
    end
  end
end
