require "rails_helper"
require 'examples/ayoconnect_examples'

RSpec.describe Channel::Ayoconnect::ElectricityPostpaid, type: :model do
  include_context 'ayoconnect_lets'

  let(:customer_number) {"516070377764"}
  let(:form) { Form::ElectricityPostpaid.new(customer_number) }
  let(:partner_ayoconnect) { build_stubbed(:electricity_postpaid_partner, :ayoconnect) }

  describe '#inquiry_to_partner' do
    subject { described_class.new(form).inquiry_to_partner }

    before do
      allow(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_ayoconnect)
    end

    context 'request success' do
      let(:status) { :success }
      let(:rc) { '300' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return valid_inquiry_response.to_json
        
        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true

        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(false)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      # dynamic key
      it 'returns expected results' do
        result = subject
        expect(result.customer_number).to eq valid_inquiry_response[:data][:customerDetails][2][:value]
        expect(result.customer_name).to eq valid_inquiry_response[:data][:customerDetails][0][:value]
        expect(result.segmentation).to eq valid_inquiry_response[:data][:productDetails][2][:value].split('/')[0]
        expect(result.power).to eq valid_inquiry_response[:data][:productDetails][2][:value].split('/')[1].to_i
        expect(result.stand_meter).to eq ('%08d - %08d' % [valid_inquiry_response[:data][:productDetails][4][:value].split(',')[0].strip.split('-').first.to_i, valid_inquiry_response[:data][:productDetails][4][:value].split(',')[-1].strip.split('-').last.to_i])
        expect(result.outstanding_bill).to eq valid_inquiry_response[:data][:productDetails][1][:value].to_i
        expect(result.unpaid_bill).to eq valid_inquiry_response[:data][:productDetails][1][:value].to_i
        expect(result.penalty_fee).to eq valid_inquiry_response[:data][:billDetails].sum { |x| x[:billId] == "0" ? 0 : x[:billInfo][1][:value].to_i }
        expect(result.amount).to eq (valid_inquiry_response[:data][:amount])
      end
    end

    context 'request success with new format' do
      let(:status) { :success }
      let(:rc) { '300' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return valid_inquiry_response_new_format.to_json

        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true

        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
          .to receive(:active?)
                .and_return(false)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      # dynamic key
      it 'returns expected results' do
        result = subject
        expect(result.customer_number).to eq valid_inquiry_response_new_format[:data][:customerDetails][2][:value]
        expect(result.customer_name).to eq valid_inquiry_response_new_format[:data][:customerDetails][0][:value]
        expect(result.segmentation).to eq valid_inquiry_response_new_format[:data][:productDetails][2][:value].split('/')[0]
        expect(result.power).to eq valid_inquiry_response_new_format[:data][:productDetails][2][:value].split('/')[1].to_i
        expect(result.stand_meter).to eq ('%08d - %08d' % [valid_inquiry_response_new_format[:data][:productDetails][4][:value].split(',')[0].strip.split('-').first.to_i, valid_inquiry_response[:data][:productDetails][4][:value].split(',')[-1].strip.split('-').last.to_i])
        expect(result.outstanding_bill).to eq valid_inquiry_response_new_format[:data][:productDetails][1][:value].to_i
        expect(result.unpaid_bill).to eq valid_inquiry_response_new_format[:data][:productDetails][1][:value].to_i
        expect(result.penalty_fee).to eq valid_inquiry_response_new_format[:data][:billDetails].sum { |x| x[:billId] == "0" ? 0 : x[:billInfo][1][:value].to_i }
        expect(result.amount).to eq valid_inquiry_response_new_format[:data][:amount]
        expect(result.bills[0][:bill_period]).to eq Date.new(2024, 1, 1)
        expect(result.bills[1][:bill_period]).to eq Date.new(2024, 2, 1)
        expect(result.bills[2][:bill_period]).to eq Date.new(2024, 3, 1)
      end
    end

    context 'invalid number' do
      let(:status) { :failed }
      let(:rc) { '304' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return failed_inquiry_response.to_json

        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true

        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(false)
      end

      it 'raises error' do
        expect { subject }.to raise_error(::Exceptions::UnregisteredNumber)
      end
    end

    context 'inactive provider' do
      let(:status) { :failed }
      let(:rc) { '313' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return failed_partner_inquiry_response.to_json

        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true

        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(false)
      end

      it 'raises error' do
        expect { subject }.to raise_error(::Exceptions::TransactionCannotBeDone)
      end
    end

    context 'invalid number' do
      let(:status) { :timeout }
      let(:rc) { 'error' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).at_most(5).times.and_return(true)
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)

        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed).and_return(autoswitch_instance)
        expect(autoswitch_instance).to receive(:run!).at_most(5).times.and_return true

        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .at_most(5).times
            .and_return(false)
      end

      it 'raises error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end
  end

  describe '#create_transaction' do
    let(:trx) { build(:postpaid_transaction_with_bill, :partner_ayoconnect) }
    subject { described_class.new(trx).create_transaction }

    before do
      allow(::ElectricityPostpaidPartner).to receive(:find_by).with(name: 'ayoconnect').and_return(partner_ayoconnect)
      expect_any_instance_of(Channel::Ayoconnect::ElectricityPostpaid).to receive(:inquiry).and_return valid_inquiry_response
    end

    context 'request success' do
      let(:status) { :pending }
      let(:rc) { '299' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return valid_create_response.to_json
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.customer_number).to eq valid_create_response[:data][:accountNumber]
        expect(result.partner_transaction_id).to eq valid_create_response[:data][:transactionId].to_s
        expect(result.status).to eq PARTNER_STATUS[AYOCONNECT][status.to_s]
      end
    end

    context 'failed cause operator Issue' do
      let(:status) { :failed }
      let(:rc) { '100' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return failed_create_response.to_json
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.customer_number).to be_nil
        expect(result.partner_transaction_id).to be_nil
        expect(result.status).to eq PARTNER_STATUS[AYOCONNECT][status.to_s]
      end
    end

    context 'timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end
  end

  describe '#confirm_transaction' do
    let(:transaction) { build(:postpaid_transaction_with_bill, partner: 'ayoconnect') }

    subject { described_class.new(transaction).confirm_transaction }

    before do
      allow(::ElectricityPostpaidPartner).to receive(:find_by).with(name: 'ayoconnect').and_return(partner_ayoconnect)
    end

    context 'success confirm' do
      let(:status) { :success }
      let(:rc) { '0' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return check_status_success_response.to_json
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.reference_number).to eq check_status_success_response[:data][:token]
        expect(result.status).to eq ::Postpaid::Constant::SUCCESS
      end
    end

    context 'failed confirm' do
      let(:status) { :failed }
      let(:rc) { '103' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return check_status_fail_response.to_json
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.reference_number).to eq check_status_fail_response[:data][:token]
        expect(result.status).to eq ::Postpaid::Constant::FAILED
      end
    end

    context 'still pending transaction' do
      let(:status) { :pending }
      let(:rc) { '299' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return check_status_pending_response.to_json
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.reference_number).to eq check_status_pending_response[:data][:token]
        expect(result.status).to eq ::Postpaid::Constant::PENDING
      end
    end

    context 'error when making request' do
      let(:status) { :error }
      let(:rc) { 'error' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).at_most(5).times.and_return(true)

        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception)
      end

      it 'does not raise error' do
        expect { subject }.to raise_error(RestClient::Exception)
      end
    end

    context 'partner transaction not found' do
      let(:status) { :pending }
      let(:rc) { '188' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(unavailable_check_trx_response.to_json)
      end

      it 'does not raise error' do
        expect { subject }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end
  end
end
