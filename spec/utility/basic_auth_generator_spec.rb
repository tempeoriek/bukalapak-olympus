# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BasicAuthGenerator, type: :model do
  describe '[REST-2537] .generate' do
    let(:username) { 'some_username' }
    let(:password) { 'some_password' }
    
    let(:token) { Base64.strict_encode64("#{username}:#{password}") }

    subject { described_class.generate(username, password) }

    it 'generates the basic auth token' do
      expect(subject).to eq "Basic #{token}"
    end
  end
end
