require 'rails_helper'

RSpec.describe MwsPublisher, type: :model do
  let(:job_name) { 'job_name' }
  let(:delay) { 0 }
  let(:routing_key) { 'routing_key' }
  let(:priority) { 'normal' }
  let(:payload) { { phone_number: '628561234567' } }
  let(:success_response) { ['response', nil] }

  context 'when enqueue succeed' do
    before do
      allow(MwsApiClient::Job)
        .to receive(:enqueue)
        .with(job_name, delay, routing_key, priority, payload.to_json)
        .and_return(success_response)
    end

    it 'does not return nil' do
      expect(MwsPublisher.publish(job_name, routing_key, payload)).not_to be_nil
    end
  end

  context 'when enqueue failed' do
    before do
      allow(MwsApiClient::Job)
        .to receive(:enqueue)
        .with(job_name, delay, routing_key, priority, payload.to_json)
        .and_raise(MwsApiClient::Errors::ConnectionFailed.new('failed'))
    end

    it 'returns nil' do
      expect(MwsPublisher.publish(job_name, routing_key, payload)).to be_nil
    end
  end
end
