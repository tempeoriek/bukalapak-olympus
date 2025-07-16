# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Form::Anonymization, type: :model do
  let(:user_id) { '123' }
  let(:params) do
    {
      actor_id: '1',
      user_id: user_id,
      username: "someusername",
      name: 'some name',
      email: "some@email.test",
      confirmed: false,
      phone: '6281000000',
      phone_confirmed: false
    }
  end

  subject { described_class.new(params) }

  describe 'O2OVPE-2375: .valid?' do
    context 'when form is valid' do
      it { expect(subject.valid?).to eq(true) }
    end

    context 'when form is invalid' do
      let(:user_id) { '' }

      it { expect(subject.valid?).to eq(false) }
    end
  end
end