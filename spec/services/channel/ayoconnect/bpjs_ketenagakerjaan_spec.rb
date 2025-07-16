require "rails_helper"
require 'examples/ayoconnect_examples'

RSpec.describe Channel::Ayoconnect::BpjsKetenagakerjaan, type: :model do
  include_context 'ayoconnect_lets'

  let(:customer_number) { '210800004501' }
  let(:payment_period) { 1 }
  let(:form) { Form::BpjsKetenagakerjaan.new(customer_number, payment_period) }
  let(:partner_ayoconnect) { build_stubbed(:bpjs_ketenagakerjaan_partner) }

  describe 'O2OVPD-1497: #inquiry_to_partner' do
    subject { described_class.new(form).inquiry_to_partner }

    before do
      allow(::BpjsKetenagakerjaanPartner).to receive(:find_by).with(state: 'active').and_return(partner_ayoconnect)
    end

    context 'when request success' do
      let(:status) { :success }
      let(:rc) { '300' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(false)
      end

      context 'when type is pu' do
        let(:partner_inquiry_response) { valid_bpjs_ketenagakerjaan_pu_inquiry_response }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return partner_inquiry_response.to_json
        end

        it 'does not raise error' do
          expect { subject }.not_to raise_error
        end

        it 'returns expected results' do
          result = subject
          expect(result.customer_number).to eq partner_inquiry_response[:data][:accountNumber]
          expect(result.customer_name).to eq partner_inquiry_response[:data][:customerName]
          expect(result.amount).to eq 110_490
          expect(result.bukalapak_admin_charge).to eq(1000)
          expect(result.partner_admin_charge).to eq(500)
          expect(result.payment_period).to eq(payment_period)
          expect(result.start_bill_period).to eq(Date.new(2021, 9, 1))
          expect(result.division).to eq partner_inquiry_response[:data][:productDetails][1][:value]
          expect(result.npp).to eq partner_inquiry_response[:data][:productDetails][0][:value]
          expect(result.bills.size).to eq 1
          bill_info = partner_inquiry_response[:data][:billDetails][0][:billInfo]
          expect(result.bills[0][:jht]).to eq bill_info[0][:value].to_i
          expect(result.bills[0][:jkk]).to eq bill_info[1][:value].to_i
          expect(result.bills[0][:jkm]).to eq bill_info[2][:value].to_i
          expect(result.bills[0][:jkp]).to eq bill_info[3][:value].to_i
          expect(result.bills[0][:jp]).to eq bill_info[4][:value].to_i
        end
      end

      context 'when type is bpu' do
        let(:customer_number) { '1871010907930009' }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return partner_inquiry_response.to_json
        end

        context 'when no unpaid bills' do
          let(:partner_inquiry_response) { valid_bpjs_ketenagakerjaan_bpu_inquiry_response }

          it 'does not raise error' do
            expect { subject }.not_to raise_error
          end

          it 'returns expected results' do
            result = subject
            expect(result.customer_number).to eq partner_inquiry_response[:data][:accountNumber]
            expect(result.customer_name).to eq partner_inquiry_response[:data][:customerName]
            expect(result.amount).to eq 38300
            expect(result.bukalapak_admin_charge).to eq(1000)
            expect(result.partner_admin_charge).to eq(500)
            expect(result.payment_period).to eq(payment_period)
            expect(result.start_bill_period).to eq(Date.new(2021, 8, 27))
            expect(result.end_bill_period).to eq(Date.new(2021, 9, 26))
            expect(result.bill_code).to eq partner_inquiry_response[:data][:productDetails][3][:value]
            expect(result.branch_name).to eq partner_inquiry_response[:data][:productDetails][2][:value]
            expect(result.bills.size).to eq 1
            bill_info = partner_inquiry_response[:data][:billDetails][0][:billInfo]
            expect(result.bills[0][:jht]).to eq bill_info[0][:value].to_i
            expect(result.bills[0][:jkk]).to eq bill_info[1][:value].to_i
            expect(result.bills[0][:jkm]).to eq bill_info[2][:value].to_i
            expect(result.unpaid_bills).to eq(false)
            expect(result.unpaid_bills_text).to eq ''
          end
        end

        context 'when have an unpaid bills' do
          let(:partner_inquiry_response) { valid_bpjs_ketenagakerjaan_bpu_inquiry_response_with_tunggakan }

          it 'does not raise error' do
            expect { subject }.not_to raise_error
          end

          it 'returns expected results' do
            result = subject
            expect(result.customer_number).to eq partner_inquiry_response[:data][:accountNumber]
            expect(result.customer_name).to eq partner_inquiry_response[:data][:customerName]
            expect(result.amount).to eq 38300
            expect(result.bukalapak_admin_charge).to eq(1000)
            expect(result.partner_admin_charge).to eq(500)
            expect(result.payment_period).to eq(payment_period)
            expect(result.start_bill_period).to eq(Date.new(2021, 8, 27))
            expect(result.end_bill_period).to eq(Date.new(2021, 9, 26))
            expect(result.bill_code).to eq partner_inquiry_response[:data][:productDetails][3][:value]
            expect(result.branch_name).to eq partner_inquiry_response[:data][:productDetails][2][:value]
            expect(result.bills.size).to eq 1
            bill_info = partner_inquiry_response[:data][:billDetails][0][:billInfo]
            expect(result.bills[0][:jht]).to eq bill_info[0][:value].to_i
            expect(result.bills[0][:jkk]).to eq bill_info[1][:value].to_i
            expect(result.bills[0][:jkm]).to eq bill_info[2][:value].to_i
            expect(result.unpaid_bills).to eq(true)
            expect(result.unpaid_bills_text).to eq partner_inquiry_response[:data][:extraFields][0][:value]
          end
        end
      end
    end

    context 'when invalid number' do
      let(:status) { :failed }
      let(:rc) { '304' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return failed_inquiry_response.to_json
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(false)
      end

      it 'raises error' do
        expect { subject }.to raise_error(::Exceptions::UnregisteredNumber)
      end
    end
  end

  describe '#create_transaction' do
    let(:transaction) { build(:bpjs_ketenagakerjaan_transaction) }

    subject { described_class.new(transaction).create_transaction }

    before do
      allow(::BpjsKetenagakerjaanPartner).to receive(:find_by).with(name: 'ayoconnect').and_return(partner_ayoconnect)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
      )).at_most(5).times.and_return(true)
    end

    context 'when payment success' do
      let(:status) { :success }
      let(:rc)     { '0' }

      context 'with bpjs ketenagakerjaan type BPU' do
        before do
          expect_any_instance_of(Channel::Ayoconnect::BpjsKetenagakerjaan).to receive(:inquiry).and_return valid_bpjs_ketenagakerjaan_bpu_inquiry_response
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return valid_create_response_bpjs_tk_bpu.to_json
        end

        it 'does not raise error' do
          expect { subject }.not_to raise_error
        end

        it 'returns expected results' do
          result = subject
          expect(result.partner_transaction_id).to eq valid_create_response_bpjs_tk_bpu[:data][:transactionId].to_s
          expect(result.status).to eq ::Postpaid::Constant::SUCCESS
        end
      end

      context 'when bpjs ketenagakerjaan type PU' do
        before do
          expect_any_instance_of(Channel::Ayoconnect::BpjsKetenagakerjaan).to receive(:inquiry).and_return valid_bpjs_ketenagakerjaan_pu_inquiry_response
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return valid_create_response_bpjs_tk_pu.to_json
        end

        it 'does not raise error' do
          expect { subject }.not_to raise_error
        end

        it 'returns expected results' do
          result = subject
          expect(result.partner_transaction_id).to eq valid_create_response_bpjs_tk_pu[:data][:transactionId].to_s
          expect(result.status).to eq ::Postpaid::Constant::SUCCESS
        end
      end
    end

    context 'when payment pending' do
      let(:status) { :pending }
      let(:rc)     { '299' }

      before do
        expect_any_instance_of(Channel::Ayoconnect::BpjsKetenagakerjaan).to receive(:inquiry).and_return valid_bpjs_ketenagakerjaan_bpu_inquiry_response
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return pending_create_response_bpjs_tk.to_json
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.partner_transaction_id).to eq pending_create_response_bpjs_tk[:data][:transactionId].to_s
        expect(result.status).to eq ::Postpaid::Constant::PENDING
      end
    end

    context 'when payment failed' do
      let(:status) { :failed }
      let(:rc)     { '100' }

      before do
        expect_any_instance_of(Channel::Ayoconnect::BpjsKetenagakerjaan).to receive(:inquiry).and_return valid_bpjs_ketenagakerjaan_bpu_inquiry_response
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return failed_create_response.to_json
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.partner_transaction_id).to be_nil
        expect(result.status).to eq ::Postpaid::Constant::FAILED
      end
    end

    context 'when timeout' do
      let(:status) { :timeout }
      let(:rc)     { 'error' }

      before do
        expect_any_instance_of(Channel::Ayoconnect::BpjsKetenagakerjaan).to receive(:inquiry).and_return valid_bpjs_ketenagakerjaan_bpu_inquiry_response
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'when error' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        expect_any_instance_of(Channel::Ayoconnect::BpjsKetenagakerjaan).to receive(:inquiry).and_return valid_bpjs_ketenagakerjaan_bpu_inquiry_response
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception)
      end

      it 'should raise error' do
        expect { subject }.to raise_error(RestClient::Exception)
      end

    end
  end

  describe '#confirm_transaction' do
    let(:transaction) { build(:bpjs_ketenagakerjaan_transaction) }

    subject { described_class.new(transaction).confirm_transaction }

    before { allow(::BpjsKetenagakerjaanPartner).to receive(:find_by).with(name: 'ayoconnect').and_return(partner_ayoconnect) }

    context 'when success confirm' do
      let(:status) { :success }
      let(:rc)     { '0' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)
      end

      context 'with bpjs ketenagakerjaan type BPU' do
        before { allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return check_status_success_response_bjps_tk_bpu.to_json }

        it 'does not raise error' do
          expect { subject }.not_to raise_error
        end

        it 'returns expected results' do
          result = subject
          expect(result.reference_number).to eq check_status_success_response_bjps_tk_bpu[:data][:token]
          expect(result.partner_transaction_id).to eq check_status_success_response_bjps_tk_bpu[:data][:transactionId].to_s
          expect(result.status).to eq ::Postpaid::Constant::SUCCESS
        end
      end

      context 'with bpjs ketenagakerjaan type PU' do
        before { allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return check_status_success_response_bjps_tk_pu.to_json }

        it 'does not raise error' do
          expect { subject }.not_to raise_error
        end

        it 'returns expected results' do
          result = subject
          expect(result.reference_number).to eq check_status_success_response_bjps_tk_pu[:data][:token]
          expect(result.partner_transaction_id).to eq check_status_success_response_bjps_tk_pu[:data][:transactionId].to_s
          expect(result.status).to eq ::Postpaid::Constant::SUCCESS
        end
      end
    end

    context 'when failed confirm' do
      let(:status) { :failed }
      let(:rc)     { '103' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return check_status_failed_response_bjps_tk.to_json
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

    context 'when pending confirm' do
      let(:status) { :pending }
      let(:rc)     { '299' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return check_status_in_process_response_bjps_tk.to_json
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.reference_number).to eq check_status_fail_response[:data][:token]
        expect(result.status).to eq ::Postpaid::Constant::PENDING
      end
    end

    context 'when error' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).at_most(5).times.and_return(true)

        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception)
      end

      it 'should raise error' do
        expect { subject }.to raise_error(RestClient::Exception)
      end
    end

    context 'when transaction not found in partner' do
      let(:status) { :pending }
      let(:rc)     { '188' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :biller_product, :product => described_class::PRODUCT_TYPE, :status => status, :response_code => rc
        )).and_return(true)

        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(unavailable_check_trx_response.to_json)
      end

      it 'should raise error' do
        expect { subject }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end
  end
end
