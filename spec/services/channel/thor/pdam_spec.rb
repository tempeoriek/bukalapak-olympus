require 'rails_helper'
require 'examples/thor_examples'

RSpec.describe Channel::Thor::Pdam, type: :model do
  include_context 'thor_lets'

  let(:pdam_operator)   { build_stubbed(:pdam_operator) }
  let(:customer_number) { '199890000000' }
  let(:access_token)    { 'token.dummy.abc' }

  before do
    Rails.cache.write(described_class::ACCESS_TOKEN_CACHE_KEY, access_token, expires_in: 10_000)
    RedisOlympus.flushall # remove all keys in Redis
  end

  describe 'O2OVPD-1589, O2OVPE-931: #inquiry_to_partner' do
    let(:restclient_request) { RestClient::Request.new(method: :post, url: Channel::Config::THOR_HOST + described_class::INQUIRY_URL) }
    let(:form)               { Form::Pdam.new(customer_number, pdam_operator.id) }

    subject { described_class.new(form).inquiry_to_partner }

    before do
      allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
      expect(::Toggle::CircuitBreaker::Thor)
        .to receive(:active?)
        .and_return(false)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)
    end

    context 'when success' do
      let(:status)           { :success }
      let(:rc)               { '0000' }
      let(:partner_response) { success_inquiry_response }

      context 'with bills present' do
        before do
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        it 'not raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.not_to raise_error
          expect(subject.bills.first[:amount]).to eq 100_000
          expect(subject.bills.first[:cubication]).to eq("402 - 458")
          expect(subject.amount).to eq(partner_response[:water_bill_customer][:total_price].to_i)
        end
      end

      context 'with bills nil' do
        let(:status)           { :success }
        let(:rc)               { '0000' }
        let(:partner_response) { success_inquiry_response }

        before do
          partner_response[:water_bill_customer][:bills] = nil
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        it 'should raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.not_to raise_error
        end
      end

      context 'with single bill' do
        let(:pdam_operator) { build_stubbed(:pdam_operator, :pdam_jakarta) }

        before do
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        context 'when usage is not empty string' do
          it 'segel and retribution should not nil' do
            result = subject
            expect(result.segel).to eq 3000
            expect(result.retribution).to eq 1000
            expect(result.stand_meter).to eq '402 - 458'
            expect(result.bills.first[:amount]).to eq 100_000
            expect(result.amount).to eq(partner_response[:water_bill_customer][:total_price].to_i)
            expect(result.details[:sub_segment]).to eq(partner_response[:water_bill_customer][:sub_segment])
            expect(result.details[:biller_ref]).to eq(partner_response[:water_bill_customer][:biller_ref])
            expect(result.address).not_to be_nil
            expect(result.usage).to eq(56)
            expect(result.details[:usage_unit]).to be_nil
          end
        end

        context 'when usage is empty string' do
          let(:partner_response) do
            response = success_inquiry_response
            response[:water_bill_customer][:usage] = ''
            response[:water_bill_customer][:bills].first[:usage] = ''

            response
          end

          it 'segel and retribution should not nil' do
            result = subject
            expect(result.segel).to eq 3000
            expect(result.retribution).to eq 1000
            expect(result.stand_meter).to eq '402 - 458'
            expect(result.bills.first[:amount]).to eq 100_000
            expect(result.amount).to eq(partner_response[:water_bill_customer][:total_price].to_i)
            expect(result.details[:sub_segment]).to eq(partner_response[:water_bill_customer][:sub_segment])
            expect(result.details[:biller_ref]).to eq(partner_response[:water_bill_customer][:biller_ref])
            expect(result.address).not_to be_nil
            expect(result.usage).to be_nil
          end
        end

        context 'when usage contains unit' do
          let(:partner_response) do
            response = success_inquiry_response
            response[:water_bill_customer][:usage] = '56 M3'
            response[:water_bill_customer][:bills].first[:usage] = '56 M3'

            response
          end

          it 'usage should has a correct value' do
            result = subject
            expect(result.usage).to eq(56)
            expect(result.details[:usage_unit]).to eq('M3')
          end
        end

        context 'when sub_segment is only a value' do
          let(:partner_response) do
            response = success_inquiry_response
            response[:water_bill_customer][:sub_segment] = 'GOL 3A'
  
            response
          end
  
          it 'details should have correct sub_segment' do
            result = subject
            expect(result.details[:sub_segment]).to eq('GOL 3A')
          end
        end
  
        context 'when sub_segment consists of value and description' do
          let(:partner_response) do
            response = success_inquiry_response
            response[:water_bill_customer][:sub_segment] = 'Group rate: GOL 3A, Description: Rumah Tangga'
  
            response
          end
  
          it 'details should have correct sub_segment' do
            result = subject
            expect(result.details[:sub_segment]).to eq('GOL 3A')
          end
        end
      end

      context 'with multiple bill' do
        let(:pdam_operator) { build_stubbed(:pdam_operator, :pdam_jakarta) }
        let(:partner_response_multiple_bill) { success_inquiry_multiple_bill_response }

        before do
          response = RestClient::Response.create(partner_response_multiple_bill.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        context 'when all usage is not empty' do
          it 'segel and retribution should not nil' do
            result = subject
            expect(result.segel).to eq 7000
            expect(result.retribution).to eq 3000
            expect(result.stand_meter).to eq '402 - 600'
            expect(result.bills.first[:amount]).to eq 100_000
            expect(result.bills.last[:amount]).to eq 100_000
            expect(result.amount).to eq(partner_response_multiple_bill[:water_bill_customer][:total_price].to_i)
            expect(result.details[:sub_segment]).to eq(partner_response[:water_bill_customer][:sub_segment])
            expect(result.details[:biller_ref]).to eq(partner_response[:water_bill_customer][:biller_ref])
            expect(result.address).not_to be_nil
            expect(result.usage).to eq(56)
          end
        end

        context 'when some of usage is empty' do
          let(:partner_response_multiple_bill) do
            response = success_inquiry_multiple_bill_response
            response[:water_bill_customer][:usage] = ''
            response[:water_bill_customer][:bills].each_with_index do |b, index|
              next index == 0
              b[:usage] = ''
            end

            response
          end

          it 'segel and retribution should not nil' do
            result = subject
            expect(result.segel).to eq 7000
            expect(result.retribution).to eq 3000
            expect(result.stand_meter).to eq '402 - 600'
            expect(result.bills.first[:amount]).to eq 100_000
            expect(result.bills.last[:amount]).to eq 100_000
            expect(result.amount).to eq(partner_response_multiple_bill[:water_bill_customer][:total_price].to_i)
            expect(result.details[:sub_segment]).to eq(partner_response[:water_bill_customer][:sub_segment])
            expect(result.details[:biller_ref]).to eq(partner_response[:water_bill_customer][:biller_ref])
            expect(result.address).not_to be_nil
            expect(result.usage).not_to be_nil
          end      

          context 'when usage contains unit' do
            let(:partner_response_multiple_bill) do
              response = success_inquiry_multiple_bill_response
              response[:water_bill_customer][:usage] = ''
              response[:water_bill_customer][:bills].each_with_index do |b, index|
                b[:usage] = '56 M3'
              end
  
              response
            end

            it 'usage should has a correct value' do
              result = subject
              expect(result.usage).to eq(112)
              expect(result.details[:usage_unit]).to eq('M3')
            end
          end
        end

        context 'when all of usage is empty' do
          let(:partner_response_multiple_bill) do
            response = success_inquiry_multiple_bill_response
            response[:water_bill_customer][:usage] = ''
            response[:water_bill_customer][:bills].each do |b|
              b[:usage] = ''
            end

            response
          end

          it 'segel and retribution should not nil' do
            result = subject
            expect(result.segel).to eq 7000
            expect(result.retribution).to eq 3000
            expect(result.stand_meter).to eq '402 - 600'
            expect(result.bills.first[:amount]).to eq 100_000
            expect(result.bills.last[:amount]).to eq 100_000
            expect(result.amount).to eq(partner_response_multiple_bill[:water_bill_customer][:total_price].to_i)
            expect(result.details[:sub_segment]).to eq(partner_response[:water_bill_customer][:sub_segment])
            expect(result.details[:biller_ref]).to eq(partner_response[:water_bill_customer][:biller_ref])
            expect(result.address).not_to be_nil
            expect(result.usage).to be_nil
          end
        end
      end
    end

    context 'when failed' do
      context 'with error customer number not registered' do
        let(:status)           { :failed }
        let(:rc)               { '0035' }
        let(:partner_response) { failed_inquiry_response }

        before do
          partner_response[:water_bill_customer][:response_code] = '0035'
          partner_response[:water_bill_customer][:message] = 'unregistered user'
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)

          autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success, operator_id: '1')
          allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success, operator_id: anything).and_return(autoswitch_instance)
          allow(autoswitch_instance).to receive(:run!).and_return true
        end

        it 'should raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.to raise_error(::Exceptions::UnregisteredNumber)
        end
      end

      context 'with error bill already paid' do
        let(:status)           { :failed }
        let(:rc)               { '0088' }
        let(:partner_response) { failed_inquiry_response }

        before do
          partner_response[:water_bill_customer][:response_code] = '0088'
          partner_response[:water_bill_customer][:message] = 'bills are already paid'
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)

          autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success, operator_id: '1')
          allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success, operator_id: anything).and_return(autoswitch_instance)
          allow(autoswitch_instance).to receive(:run!).and_return true
        end

        it 'should raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.to raise_error(::Exceptions::BillAlreadyPaid)
        end
      end

      context 'with error timeout with rc' do
        let(:status)           { :failed }
        let(:rc)               { '0068' }
        let(:partner_response) { failed_inquiry_response }

        before do
          partner_response[:water_bill_customer][:response_code] = '0068'
          partner_response[:water_bill_customer][:message] = 'timeout'
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)

          autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed, operator_id: '1')
          allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed, operator_id: anything).and_return(autoswitch_instance)
          expect(autoswitch_instance).to receive(:run!).and_return true
        end

        it 'should raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.to raise_error(::Exceptions::Thor::DefaultError)
        end
      end

      context 'with error timeout' do
        let(:status)           { :timeout }
        let(:rc)               { 'error' }

        before do
          allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::OpenTimeout)

          autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed, operator_id: '1')
          allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed, operator_id: anything).and_return(autoswitch_instance)
          expect(autoswitch_instance).to receive(:run!).at_most(5).times.and_return true
        end

        it 'should raise error' do
          expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
        end
      end
    end
  end

  describe 'O2OVPD-602, O2OVPD-1589: #create_transaction' do
    let(:transaction)        { build_stubbed(:pdam_transaction_with_bill, :pending, :partner_vsi_thor) }
    let(:restclient_request) { RestClient::Request.new(method: :post, url: Channel::Config::THOR_HOST + described_class::CREATE_TRANSACTION_URL) }
    let(:restclient_request_advice) { RestClient::Request.new(method: :get, url: Channel::Config::THOR_HOST + described_class::CONFIRM_URL + transaction.id.to_s) }
    let(:advice_response_transaction_not_found) { failed_get_transaction_response.to_json }

    subject { described_class.new(transaction).create_transaction }

    before do
      allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
      advice_response = RestClient::Response.create(advice_response_transaction_not_found, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request_advice)
      allow(Channel::Connection::Http).to receive(:get).and_return(advice_response)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)
    end

    context 'when success' do
      let(:status)           { :success }
      let(:rc)               { '0000' }
      let(:partner_response) { success_create_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'returns success' do
        expect { subject }.not_to raise_error
      end

      it 'return expected results' do
        result = subject
        expect(result.status).to eq SUCCESS
        expect(result.details[:sub_segment]).to eq(partner_response[:water_bill_transaction][:sub_segment])
        expect(result.details[:biller_ref]).to eq(partner_response[:water_bill_transaction][:biller_ref])
        expect(result.address).to eq(partner_response[:water_bill_transaction][:address])
      end

      context 'when usage contains unit' do
        let(:partner_response) do
          response = success_create_transaction_response
          response[:water_bill_transaction][:usage] = '56 M3'
          response[:water_bill_transaction][:bills].first[:usage] = '56 M3'

          response
        end

        it 'usage_unit should has a correct value' do
          result = subject
          expect(result.details[:usage_unit]).to eq('M3')
        end
      end
    end

    context 'when pending' do
      let(:status)           { :pending }
      let(:rc)               { '0063' }
      let(:partner_response) { pending_create_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.status).to eq PENDING
        expect(result.details[:sub_segment]).to eq(partner_response[:water_bill_transaction][:sub_segment])
        expect(result.details[:biller_ref]).to eq(partner_response[:water_bill_transaction][:biller_ref])
        expect(result.address).to eq(partner_response[:water_bill_transaction][:address])
      end

      context 'when usage contains unit' do
        let(:partner_response) do
          response = pending_create_transaction_response
          response[:water_bill_transaction][:usage] = '56 M3'
          response[:water_bill_transaction][:bills].first[:usage] = '56 M3'

          response
        end

        it 'usage_unit should has a correct value' do
          result = subject
          expect(result.details[:usage_unit]).to eq('M3')
        end
      end
    end

    context 'when failed' do
      let(:status)           { :failed }
      let(:rc)               { '0036' }
      let(:partner_response) { failed_create_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.status).to eq FAILED
      end
    end

    context 'with restclient timeout' do
      let(:status) { :timeout }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'with other restclient exceptions' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exception)
      end

      it 'raises error' do
        expect { subject }.to raise_error(RestClient::Exception)
      end
    end

    context 'with other errors' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
      end

      it 'raises error' do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end

  describe 'O2OVPD-626: #confirm_transaction' do
    let(:transaction)        { build_stubbed(:pdam_transaction_with_bill, :paid, :partner_vsi_thor) }
    let(:restclient_request) { RestClient::Request.new(method: :get, url: Channel::Config::THOR_HOST + described_class::CONFIRM_URL + transaction.id.to_s) }

    subject { described_class.new(transaction).confirm_transaction }

    before do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)
    end

    context 'when success' do
      let(:status)           { :success }
      let(:rc)               { '0000' }
      let(:partner_response) { success_get_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'return expected results' do
        result = subject
        expect(result.status).to eq SUCCESS
      end
    end

    context 'when pending' do
      let(:status)           { :pending }
      let(:rc)               { '0063' }
      let(:partner_response) { pending_get_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.status).to eq PENDING
      end
    end

    context 'when order not found' do
      let(:status)           { :error }
      let(:rc)               { '0092' }
      let(:partner_response) { failed_get_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'should raise error' do
        expect { subject }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end

    context 'with restclient timeout' do
      let(:status) { :timeout }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'with other restclient exceptions' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get).and_raise(RestClient::Exception)
      end

      it 'raises error' do
        expect { subject }.to raise_error(RestClient::Exception)
      end
    end

    context 'with other errors' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get).and_raise(StandardError)
      end

      it 'raises error' do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
