require "rails_helper"
require 'examples/tektaya_examples'

RSpec.shared_examples 'the expected requests' do
  let(:sleep_window) { 60 }
  let(:time_window) { 30 }
  let(:volume_threshold) { 10 }
  let(:error_threshold) { 50 }
  let(:circuitbox_configuration) do
    {
      exceptions: [Exceptions::SocketConnectionTimeout, RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT],
      sleep_window: sleep_window,
      time_window: time_window,
      volume_threshold: volume_threshold,
      error_threshold: error_threshold
    }
  end

  context 'when circuit box is in open state' do
    let(:status) { :open }
    let(:rc) { 'error' }

    before do
      expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
        .to receive(:active?)
        .and_return(true)

      expect(::CircuitBreaker)
        .to receive(:run)
        .with(:tektaya_inquiry, circuitbox_configuration)
        .and_raise(Exceptions::CircuitOpen)

      allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(Exceptions::CircuitOpen)
    end

    it 'will raise circuit open error' do
      expect { subject }.to raise_error(Exceptions::CircuitOpen)
    end
  end

  context 'when RestClient::Exception' do
    let(:status) { :error }
    let(:rc) { 'error' }

    context 'when circuit breaker toggle is not active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(false)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exception)
      end

      it 'will raise error RestClient::Exception' do
        expect { subject }.to raise_error(RestClient::Exception)
      end
    end

    context 'when circuit breaker toggle is active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exception)
      end

      it 'will raise error RestClient::Exception' do
        expect { subject }.to raise_error(RestClient::Exception)
      end
    end
  end

  context 'when success request' do
    let(:status) { :success }
    let(:rc) { '00' }
    let(:partner_response) { valid_single_bill_inquiry_response.to_json }

    context 'when circuit breaker toggle is not active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(false)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject).to eq valid_single_bill_inquiry_response.with_indifferent_access
      end
    end

    context 'when circuit breaker toggle is active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject).to eq valid_single_bill_inquiry_response.with_indifferent_access
      end
    end
  end

  context 'when timeout' do
    let(:status) { :timeout }
    let(:rc) { 'error' }

    context 'when circuit breaker toggle is not active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(false)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'when circuit breaker toggle is active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(true)

        expect(::CircuitBreaker)
          .to receive(:run)
          .with(:tektaya_inquiry, circuitbox_configuration)
          .and_raise(RestClient::Exceptions::OpenTimeout)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end
  end

  context 'when other exceptions happened' do
    let(:status) { :error }
    let(:rc) { 'error' }

    context 'when circuit breaker toggle is not active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(false)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
      end

      it 'raises error' do
        expect { subject }.to raise_error(StandardError)
      end
    end

    context 'when circuit breaker toggle is active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(true)

        expect(::CircuitBreaker)
          .to receive(:run)
          .with(:tektaya_inquiry, circuitbox_configuration)
          .and_raise(StandardError)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
      end

      it 'raises error' do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end

  context 'when failed response' do
    let(:status) { :failed }
    let(:rc) { '97' }
    let(:partner_response) { failed_inquiry_response.to_json }

    context 'when circuit breaker toggle is not active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(false)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when circuit breaker toggle is active' do
      before do
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya)
          .to receive(:active?)
          .and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'raise error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end

RSpec.describe Channel::Tektaya::Base, type: :model do
  include_context 'tektaya_lets'

  let(:customer_number) { "516070377764" }
  let(:form_normal) { Form::ElectricityPostpaid.new(customer_number) }
  let(:form_mitra) { Form::ElectricityPostpaid.new(customer_number, nil, nil, "agent") }
  let(:form_bukaconnect) { Form::ElectricityPostpaid.new(customer_number, nil, nil, "collecting_agent") }
  let(:transaction) { build(:postpaid_transaction_with_bill, :collecting_agent) }
  let(:url) { 'https://somewhat.com/n/v7/pln-postpaid' }
  let(:partner_object) { build(:electricity_postpaid_partner, :sepulsa) }
  let(:payload) {
    {
      mti: '38',
      kdproduk: '200',
      userid: 'ABCDE',
      password: 'VWXYZ',
      bit62: "12345",
      sessionkey: 'somesessionkey',
      idpel: '516070377764',
      trxid: 'ELP-123'
    }
  }

  before do
    allow(::ElectricityPostpaidPartner).to receive(:find_by).and_return(partner_object)
  end

  describe "#request from normal user" do
    context 'with retry option true' do
      subject { Channel::Tektaya::Base.new(form_normal).request(url, payload, with_retry: true) }
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).at_most(Channel::Config::DEFAULT_RETRY_ATTEMPTS).times.and_return(true)
      end

      it_behaves_like 'the expected requests'
    end

    context 'with retry option false' do
      subject { Channel::Tektaya::Base.new(form_normal).request(url, payload, with_retry: false) }
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).exactly(1).times.and_return(true)
      end

      it_behaves_like 'the expected requests'
    end
  end

  describe "#request from mitra user" do
    context 'with retry option true' do
      subject { Channel::Tektaya::Base.new(form_mitra).request(url, payload, with_retry: true) }
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).at_most(Channel::Config::DEFAULT_RETRY_ATTEMPTS).times.and_return(true)
      end

      it_behaves_like 'the expected requests'
    end

    context 'with retry option false' do
      subject { Channel::Tektaya::Base.new(form_mitra).request(url, payload, with_retry: false) }
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).exactly(1).times.and_return(true)
      end

      it_behaves_like 'the expected requests'
    end
  end

  describe "#request from bukaconnect user" do
    let(:partner_object) { build(:electricity_postpaid_partner, :sepulsa_bukaconnect) }

    context 'with retry option true' do
      subject { Channel::Tektaya::Base.new(form_bukaconnect).request(url, payload, with_retry: true) }
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).at_most(Channel::Config::DEFAULT_RETRY_ATTEMPTS).times.and_return(true)
      end

      it_behaves_like 'the expected requests'
    end

    context 'with retry option false' do
      subject { Channel::Tektaya::Base.new(form_bukaconnect).request(url, payload, with_retry: false) }
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).exactly(1).times.and_return(true)
      end

      it_behaves_like 'the expected requests'
    end
  end

  describe "cache to redis" do
    let(:product_type) { ELECTRICITY_PRODUCT }
    let(:action) { "inquiry" }
    let(:partner) { TEKTAYA }
    let(:reference_id) { '0812345567678' }
    let(:response_code) { MiddlemanResponseMapperUtility::TektayaRC::BILL_ALREADY_PAID }

    subject {Channel::Tektaya::Base.new(form_normal).cache_partner_response(product_type, action, partner, reference_id, response_code) }
    context "when succesfully caching partner response with ELECTRICITY_PRODUCT" do
      before {
        expect(RedisOlympus).to receive(:set).with(kind_of(String), response_code, hash_including(:ex))
      }
      it do
        is_expected.to be_nil
      end
    end
  end
end
