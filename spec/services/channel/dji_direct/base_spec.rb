require "rails_helper"
include Postpaid::Constant

RSpec.describe Channel::Dji::Base, type: :model do
  let(:form) { Form::BpjsKesehatan.new('8888801306460946', '01') }
  let(:bpjs_kesehatan_transaction) { build(:bpjs_kesehatan_transaction, :processed) }
  let(:security_number_key) { described_class::SECURITY_NUMBER_KEY }

  subject { Channel::Dji::BpjsKesehatan }

  let(:inquiry_payload) { "90000108888801306460946    01" }
  let(:payment_data) { Iso8583::Dji.decode(success_inquiry_response) }
  let(:payment_amount) { 53500 }

  let(:success_inquiry_response) {
    "0210B23840012AC1000C000000000000000238000000000005350001301429432341571429430130900103DJI09bukalapak0000000000200000000001DJI000342      17190000108888801381184572    0130012019143501untung basuki                 000000051000000000002500                                                                06        032F5E3E07D01351F7F1EEED505B3CD9FB42258888801381184572    BEKASI                        0128988801381184572    untung basuki                 0000000255000000000000008988801381185764    erlin dwi meiriska            000000025500000000000000000000002500000000053500003001"
  }

  let(:failed_inquiry_response) {
    "0210B23840012AC1000C000000000000000238000000000000000001301407362341571407360130900103DJI09bukalapak0000000000181400000001DJI000342      02990000108888801127985309    01032F5E3E07D01351F7F1EEED505B3CD9FB4042    NO VA SALAH,MOHON TELITI KEMBALI      003001"
  }

  let(:success_payment_response) {
    "0210B23840012AE1000C000000000000010218000000000005350001302018060101292018060130900103DJI09bukalapak0000000000230000000001DJI000342      PT.Bukalapak                            17190000108888801381184572    0130012019202325untung basuki                 0000000510000000000025006018C85EE675F68D                                                06        032F5E3E07D01351F7F1EEED505B3CD9FB42218888801381184572    untung basuki                 6018C85EE675F68D                201000000051000000000002500000000053500                                                                                                    01462812356214783003001"
  }

  let(:failed_payment_response) {
    "0210B23840012AE1000C000000000000010218000000000005350001301719220101291719220130900103DJI09bukalapak0000000000111200000001DJI000342      PT.Bukalapak                            17190000108888801381184572    0130012019172441untung basuki                 000000051000000000002500                                                                06        032F5E3E07D01351F7F1EEED505B3CD9FB4035    SALDO ANDA TIDAK MENCUKUPI     01462812356214783003001"
  }
  let(:failed_login_inquiry_response) {
    '0210B23840012AC1000C000000000000000238000000000000000001060842139171460842130106900103DJI09bukalapak0000021136633400000001DJI000342      02990000100001268646873       01032B87FFCE05A9C1CD019B0DEB5A21C98E5063    PERIODE LOGIN ANDA SUDAH BERAKHIR,SILAHKAN LOGIN ULANG     003001'
  }
  let(:sign_on_response) {
    '08108238000122C0000804000000000000021013113939110505113939101303DJI09bukalapak0000000001DJI000342      03215A8E68BB11AE83BC9E687084737E2FC001003001'
  }

  before do
    allow(Keystore).to receive(:get).with('dji:bpjs_kesehatan:reference_number').and_return 12345
    allow(RedisOlympus).to receive(:get).and_return 100
    allow(Keystore).to receive(:set).with('dji:bpjs_kesehatan:reference_number', anything).and_return true
    allow(Keystore).to receive(:set).with('dji:security_number', anything, anything).and_return true
    allow(Keystore).to receive(:increment).with('dji:bpjs_kesehatan:reference_number').and_return 123456
    allow(Keystore).to receive(:increment).with('dji:unique_number').and_return 123456
    allow(Keystore).to receive(:get).with(security_number_key).and_return "secretkey123456"

    allow(Toggles::DjiCircuitBreaker).to receive(:active?).and_return true
  end

  describe '.inquiry' do
    let(:inquiry_subject) { subject.new(form) }

    context 'when bill is found' do
      before do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Channel::Connection::Iso8583).to receive(:send).and_return success_inquiry_response
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => '00'
        )).and_return(true)
      end

      it 'does not raise error' do
        expect{ inquiry_subject.inquiry(inquiry_payload) }.not_to raise_error
      end
    end

    context 'when timeout and using retry' do

      context 'when rescue Exceptions::SocketConnectionTimeout' do
        before do
          allow(Channel::Connection::Iso8583).to receive(:send).and_raise(Exceptions::SocketConnectionTimeout)
  
          expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
            :action, :partner, :product, :biller_product, :status, :response_code => :null
          )).and_return(true)
        end
  
        it 'retries and raise error' do
          expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
          expect(Channel::Connection::Iso8583).to receive(:send).at_least(3)
          expect{ inquiry_subject.inquiry(inquiry_payload, retry_when_timeout: true) }.to raise_error(Exceptions::SocketConnectionTimeout)
        end
      end
      

      context 'when rescue to Errno::ETIMEDOUT' do
        before do
          allow(Channel::Connection::Iso8583).to receive(:send).and_raise(Errno::ETIMEDOUT)

          expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
            :action, :partner, :product, :biller_product, :status, :response_code => :null
          )).and_return(true)
        end

        it 'retries and raise error' do
          expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
          expect(Channel::Connection::Iso8583).to receive(:send).at_least(3)
          expect{ inquiry_subject.inquiry(inquiry_payload, retry_when_timeout: true) }.to raise_error(Exceptions::Dji::ErrTimeout)
        end
      end
    end

    context 'when bill is not found' do
      before do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Channel::Connection::Iso8583).to receive(:send).and_return failed_inquiry_response
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => '14'
        )).and_return(true)
      end

      it 'raise corresponding error' do
        expect { inquiry_subject.inquiry(inquiry_payload) }.to raise_error(Exceptions::TransactionCannotBeDone)
      end
    end

    context 'when login failed twice then success' do
      before do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Channel::Connection::Iso8583).to receive(:send).and_return(failed_login_inquiry_response, sign_on_response, failed_login_inquiry_response, sign_on_response, success_inquiry_response)
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => '00'
        )).once.and_return(true)
      end

      it 'does not raise error' do
        expect{ inquiry_subject.inquiry(inquiry_payload) }.not_to raise_error
      end
    end

    context 'when host unreachable' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_raise(Errno::EHOSTUNREACH)

        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => :null
        )).and_return(true)
      end

      it 'should raise error' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Channel::Connection::Iso8583).to receive(:send).once
        expect{ inquiry_subject.inquiry(inquiry_payload, retry_when_timeout: true) }.to raise_error(Exceptions::Dji::HostUnreachableError)
      end
    end
  end

  describe '.create' do
    let(:payment_subject) { subject.new(bpjs_kesehatan_transaction) }

    context 'when payment is success' do
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => '00'
        )).and_return(true)
      end
      it 'does not raise error' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Channel::Connection::Iso8583).to receive(:send).and_return success_payment_response
        expect { payment_subject.create(payment_data, payment_amount) }.not_to raise_error
        expect(bpjs_kesehatan_transaction.partner_transaction_id).to eq "20"
      end
    end

    context 'when payment is failed' do
      before do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Channel::Connection::Iso8583).to receive(:send).and_return failed_payment_response
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => '12'
        )).and_return(true)
      end
      it 'does not raise error' do
        expect { payment_subject.create(payment_data, payment_amount) }.not_to raise_error
      end
    end

    context 'when login failed once then success' do
      before do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        allow(Channel::Connection::Iso8583).to receive(:send).and_return(failed_login_inquiry_response, success_payment_response)
        expect(payment_subject).to receive(:sign_on_network).once.and_return true
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => '00'
        )).once.and_return(true)
      end
      it 'does not raise error' do
        expect { payment_subject.create(payment_data, payment_amount) }.not_to raise_error
        expect(bpjs_kesehatan_transaction.partner_transaction_id).to eq "20"
      end
    end

    context 'when host unreachable' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_raise(Errno::EHOSTUNREACH)

        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => :null
        )).and_return(true)
      end

      it 'should raise error' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Channel::Connection::Iso8583).to receive(:send).once
        expect{ payment_subject.create(payment_data, payment_amount) }.to raise_error(Exceptions::Dji::HostUnreachableError)
      end
    end
  end

  describe '.get_transaction_by_id' do
    let(:check_subject) { subject.new(bpjs_kesehatan_transaction) }
    context 'when transaction is done' do
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => '00'
        )).and_return(true)
      end
      it 'does not raise error' do
        expect(Channel::Connection::Iso8583).to receive(:send).and_return success_payment_response

        expect { check_subject.get_transaction_by_id }.not_to raise_error
      end
    end

    context 'when login failed once then success' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_return(failed_login_inquiry_response, success_payment_response)
        expect(check_subject).to receive(:sign_on_network).once.and_return true
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => '00'
        )).once.and_return(true)
      end

      it 'does not raise error' do
        expect { check_subject.get_transaction_by_id }.not_to raise_error
      end
    end

    context 'when login failed once then failed' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_return(failed_login_inquiry_response, failed_login_inquiry_response)
        expect(check_subject).to receive(:sign_on_network).once.and_return true
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => '34'
        )).once.and_return(true)
      end

      it 'does not raise error' do
        expect { check_subject.get_transaction_by_id }.to raise_error(Exceptions::PartnerTransactionNotFound)
      end
    end

    context 'when host unreachable' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_raise(Errno::EHOSTUNREACH)

        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code => :null
        )).and_return(true)
      end

      it 'should raise error partner transaction not found' do
        expect{ check_subject.get_transaction_by_id }.to raise_error(Exceptions::PartnerTransactionNotFound)
      end
    end
  end
end
