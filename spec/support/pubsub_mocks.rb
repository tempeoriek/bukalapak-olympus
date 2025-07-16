RSpec.shared_context 'pubsub_mocks', :shared_context => :metadata do
  before(:each) do
    # double pubsub class
    subscription = double(Google::Cloud::PubSub::V1::Subscription, nil?: false)
    subscriber = double(Google::Cloud::PubSub::Subscriber, start: true, stop!: true)
    received_message = double(Google::Cloud::PubSub::V1::ReceivedMessage, acknowledge!: true, data: message)
    allow(subscription).to receive(:listen).and_yield(received_message).and_return(subscriber)
    allow_any_instance_of(described_class).to receive(:subscription).and_return(subscription)
    # allow_any_instance_of(described_class).to receive(:sleep)
    allow(Subscribers::Topics).to receive(:get_delay).and_return(0.1)
  end
end
