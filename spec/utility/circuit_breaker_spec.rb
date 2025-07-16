# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::CircuitBreaker, type: :model do
  let(:url) { 'https://www.awd.com' }
  let(:opts) { { method: :get, url: url } }
  let(:circuit) { Circuitbox.circuit(:test, CIRCUITBOX_CONFIGURATION) }

  context '.run' do
    subject { described_class.run(:test) { RestClient::Request.execute(opts) } }

    before do
      stub_request(:get, url).to_return(body: { key: :value }.to_json)
    end

    context 'when circuit closed' do
      it 'success call partner' do
        expect(RestClient::Request).to receive(:execute).and_call_original
        expect { subject }.not_to raise_error
      end
    end

    context 'when circuit open timeout' do
      it 'raise open timeout error' do
        expect(RestClient::Request).to receive(:execute).and_raise(RestClient::Exceptions::OpenTimeout)
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'when circuit read timeout' do
      it 'raise read timeout error' do
        expect(RestClient::Request).to receive(:execute).and_raise(RestClient::Exceptions::ReadTimeout)
        expect { subject }.to raise_error(RestClient::Exceptions::ReadTimeout)
      end
    end

    context 'when circuit opened' do
      it 'not call partner and raise circuit open error exception' do
        expect(circuit).to receive(:run).and_raise(Circuitbox::OpenCircuitError.new(:test))
        expect(RestClient::Request).not_to receive(:execute)
        expect { subject }.to raise_error(Exceptions::CircuitOpen)
      end
    end

    context 'when request error' do
      it 'raise error' do
        expect(RestClient::Request).to receive(:execute).and_raise(StandardError)
        expect { subject }.to raise_error(StandardError)
      end
    end

    context 'when redis fail' do
      context 'before call partner' do
        context 'and partner succees' do
          it 'success call partner' do
            expect(circuit).to receive(:run).and_raise(Redis::ConnectionError)
            expect(RestClient::Request).to receive(:execute).and_call_original.once
            expect { subject }.not_to raise_error
          end
        end

        context 'and partner error' do
          it 'raise error' do
            expect(circuit).to receive(:run).and_raise(Redis::ConnectionError)
            expect(RestClient::Request).to receive(:execute).and_raise(StandardError).once
            expect { subject }.to raise_error(StandardError)
          end
        end
      end

      context 'after success call partner' do
        it 'success call partner' do
          expect(circuit).to receive(:run).and_yield.and_raise(Redis::ConnectionError)
          expect(RestClient::Request).to receive(:execute).and_call_original.once
          expect { subject }.not_to raise_error
        end
      end

      context 'after fail call partner' do
        it 'raise partner unavailable error' do
          expect(RestClient::Request).to receive(:execute).and_return(nil)
          expect(circuit).to receive(:run).and_yield.and_raise(Redis::ConnectionError)
          expect(LogBook).to receive(:error)
          expect { subject }.to raise_error(Exceptions::InternalError)
        end
      end
    end

    context 'when redis future not ready' do
      context 'before call partner' do
        context 'and partner succees' do
          it 'success call partner' do
            expect(circuit).to receive(:run).and_raise(Redis::FutureNotReady)
            expect(RestClient::Request).to receive(:execute).and_call_original.once
            expect { subject }.not_to raise_error
          end
        end

        context 'and partner error' do
          it 'raise error' do
            expect(RestClient::Request).to receive(:execute).and_raise(StandardError).once
            expect { subject }.to raise_error(StandardError)
          end
        end
      end

      context 'after success call partner' do
        it 'success call partner' do
          expect(circuit).to receive(:run).and_yield.and_raise(Redis::FutureNotReady)
          expect(RestClient::Request).to receive(:execute).and_call_original.once
          expect { subject }.not_to raise_error
        end
      end

      context 'after fail call partner' do
        it 'raise partner unavailable error' do
          expect(RestClient::Request).to receive(:execute).and_return(nil)
          expect(circuit).to receive(:run).and_yield.and_raise(Redis::FutureNotReady)
          expect(LogBook).to receive(:error)
          expect { subject }.to raise_error(Exceptions::InternalError)
        end
      end
    end
  end
end
