require "rails_helper"

RSpec.describe Channel::Sepulsa::BpjsKesehatan, type: :model do
  let(:customer_number) { '0000001430071801' }
  let(:valid_payment_period) { '01' }
  let(:invalid_payment_period) { '13' }
  let(:bpjs_kesehatan_partner) { build_stubbed(:bpjs_kesehatan_partner) }
  let(:valid_form) { Form::BpjsKesehatan.new(customer_number, valid_payment_period) }
  let(:invalid_form) { Form::BpjsKesehatan.new(customer_number, invalid_payment_period) }
  let(:inquiry_response) {
    {
      "admin_charge"  => "2500",
      "alamat_loket"  => "Jakarta",
      "amount"        => "155500",
      "datetime"      => "20200910144657",
      "kode_cabang"   => "1101",
      "kode_kab_kota" => "2122",
      "kode_loket"    => "HTH16010028",
      "merchant_code" => "6012",
      "message"       => "success",
      "nama_cabang"   => "ALTERRA INDONESIA MALANG",
      "nama_loket"    => "PT ALTERRA INDONESIA",
      "name"          => "WISHNU EKA SIDHARTA (PST: 1)",
      "no_va"         => "0000001430071801",
      "no_va_kk"      => "0000001430801801",
      "periode"       => "03",
      "phone_loket"   => "021912345",
      "premi"         => "153000",
      "product_type"  => "BPJS-KESEHATAN",
      "rc"            => "00",
      "response_code" => "00",
      "sisa"          => "000000000000",
      "stan"          => "58607513",
      "status"        => true,
      "sw_reff"       => "58607513",
      "trx_id"        => "",
      "trx_type"      => "",
      "va_count"      => "1",
    }.with_indifferent_access
  }
  let(:payment_response) {
    {
      "transaction_id"  => "143408",
      "type"            => "bpjs_kesehatan",
      "created"         => "1599726012",
      "changed"         => "1599726012",
      "customer_number" => "0000001430071801",
      "product_id" => {
        "product_id" => "34",
        "type"       => "bpjs_kesehatan",
        "label"      => "BPJS Kesehatan",
        "operator"   => "bpjs_kesehatan",
        "nominal"    => "2500",
        "price"      => 2500,
        "enabled"    => "1"
      },
      "order_id"       => "BKS-1379757",
      "price"          => "206500",
      "status"         => "pending",
      "response_code"  => "10",
      "payment_period" => "04",
      "serial_number"  => nil,
      "amount"         => "206500",
      "token"          => nil,
      "data"           => nil
    }.with_indifferent_access
  }
  let(:get_transaction_by_order_id_response) {
    {
      "self": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=BKS-5503330717",
      "first": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=BKS-5503330717\\u0026page=1",
      "last": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=BKS-5503330717\\u0026page=1",
      "list": [
        {
          "transaction_id": "146897173",
          "type": "bpjs_kesehatan",
          "created": "1599718873",
          "changed": "1599718874",
          "customer_number": "0000001430071801",
          "product_id": {
            "product_id": "93",
            "type": "bpjs_kesehatan",
            "label": "BPJS Kesehatan",
            "operator": "BPJS Kesehatan",
            "nominal": "2500",
            "price": 2500,
            "enabled": "1"
          },
          "order_id": "BKS-5503330717",
          "price": "28000",
          "status": "success",
          "response_code": "00",
          "serial_number": "74C70F9C57340544",
          "amount": "25500",
          "token": nil,
          "data": {
            "trx_type": "",
            "product_type": "BPJS-KESEHATAN",
            "stan": "91abfcfb36ac4dbb970f12d9addfd43c",
            "amount": "28000",
            "datetime": "20200910132113",
            "merchant_code": "6012",
            "rc": "00",
            "info_text": "Rincian tagihan dapat diakses di www.bpjs-kesehatan.go.id",
            "no_va": "0000001430071801",
            "no_va_kk": "0000001430071801",
            "va_count": "1",
            "periode": "01",
            "name": "ABIZAR MAULANA (PST: 1)",
            "kode_cabang": "0901",
            "nama_cabang": "Jakarta Pusat",
            "premi": "25500",
            "admin_charge": "2500",
            "sisa": "000000000000",
            "sw_reff": "74C70F9C57340544",
            "waktu_lunas": "20200910132113",
            "kode_loket": "HTH16010028",
            "nama_loket": "PT SEPULSA TEKNOLOGI INDONESIA",
            "alamat_loket": "Jakarta",
            "phone_loket": "08129753113",
            "kode_kab_kota": "3171",
            "trx_id": "",
            "message": "Successful"
          }
        }
      ]
    }.with_indifferent_access
  }
  let(:get_transaction_by_id_response) {
    {
      "transaction_id": "146897173",
      "type": "bpjs_kesehatan",
      "created": "1599718873",
      "changed": "1599718874",
      "customer_number": "0000001430071801",
      "product_id": {
        "product_id": "93",
        "type": "bpjs_kesehatan",
        "label": "BPJS Kesehatan",
        "operator": "BPJS Kesehatan",
        "nominal": "2500",
        "price": 2500,
        "enabled": "1"
      },
      "order_id": "BKS-5503330717",
      "price": "28000",
      "status": "success",
      "response_code": "00",
      "payment_period": "01",
      "serial_number": "74C70F9C57340544",
      "amount": "25500",
      "token": nil,
      "data": {
        "trx_type": "",
        "product_type": "BPJS-KESEHATAN",
        "stan": "91abfcfb36ac4dbb970f12d9addfd43c",
        "amount": "28000",
        "datetime": "20200910132113",
        "merchant_code": "6012",
        "rc": "00",
        "info_text": "Rincian tagihan dapat diakses di www.bpjs-kesehatan.go.id",
        "no_va": "0000001430071801",
        "no_va_kk": "0000001430071801",
        "va_count": "1",
        "periode": "01",
        "name": "ABIZAR MAULANA (PST: 1)",
        "kode_cabang": "0901",
        "nama_cabang": "Jakarta Pusat",
        "premi": "25500",
        "admin_charge": "2500",
        "sisa": "000000000000",
        "sw_reff": "74C70F9C57340544",
        "waktu_lunas": "20200910132113",
        "kode_loket": "HTH16010028",
        "nama_loket": "PT SEPULSA TEKNOLOGI INDONESIA",
        "alamat_loket": "Jakarta",
        "phone_loket": "08129753113",
        "kode_kab_kota": "3171",
        "trx_id": "",
        "message": "Successful"
      }
    }.with_indifferent_access
  }
  let(:valid_form_channel) { Channel::Sepulsa::BpjsKesehatan.new(valid_form) }
  let(:invalid_form_channel) { Channel::Sepulsa::BpjsKesehatan.new(invalid_form) }

  before do
    allow(BpjsKesehatanPartner).to receive(:find_by).and_return(bpjs_kesehatan_partner)
    allow(Toggles::SepulsaMitraAuth).to receive(:active?).and_return true
    allow(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(false)
  end

  context "invalid payment period" do
    it "should raise error" do
      expect { invalid_form_channel.inquiry_to_partner }.to raise_error(::Exceptions::InvalidPaymentPeriod)
    end
  end

  # context "inquiry to partner" do
  #   it "should not raise error" do
  #     allow(valid_form_channel).to receive(:inquiry).and_return(inquiry_response)
  #     expect { valid_form_channel.inquiry_to_partner }.not_to raise_error
  #   end
  # end

  describe '#get_auth' do
    subject { described_class.new(valid_form) }

    it 'return normal auth' do
      expect(subject.get_auth).to eq(described_class::AUTH)
    end

    context 'when buyer is mitra' do
      let(:valid_form) { Form::BpjsKesehatan.new(customer_number, valid_payment_period, nil, nil, AGENT_BUYER_TYPE) }

      it 'return mitra auth' do
        expect(subject.get_auth).to eq(described_class::MITRA_AUTH)
      end
    end
  end

  RSpec.shared_examples 'expected circuit breaker case' do |circuitbreaker|
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

    before do
      expect(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(true)
    end

    let(:status) { :error }
    let(:rc) { 'error' }

    context 'when Circuitbox::OpenCircuitError error occurred' do
      before do
        expect(::CircuitBreaker)
          .to receive(:run)
                .with(circuitbreaker, circuitbox_configuration)
                .and_raise(Exceptions::CircuitOpen.new)
      end

      it 'raises CircuitOpen exception' do
        expect { subject }.to raise_error(Exceptions::CircuitOpen)
      end
    end

    context 'when Circuitbox::ServiceFailureError error occurred' do
      context 'when RestClient::Exceptions::OpenTimeout raised' do
        let(:status) { :timeout }
        let(:rc) { 'error' }

        before do
          allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::OpenTimeout)
        end

        it 'raises service failure original error' do
          expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
        end
      end

      context 'when RestClient::Exceptions::ReadTimeout raised' do
        let(:status) { :timeout }
        let(:rc) { 'error' }

        before do
          allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::ReadTimeout)
        end

        it 'raises service failure original error' do
          expect { subject }.to raise_error(RestClient::Exceptions::ReadTimeout)
        end
      end
    end

    context 'when Exceptions::InternalError raised' do
      before do
        expect(::CircuitBreaker)
          .to receive(:run)
                .with(circuitbreaker, circuitbox_configuration)
                .and_raise(Exceptions::InternalError)
      end

      it 'raises internal error' do
        expect { subject }.to raise_error(Exceptions::InternalError)
      end
    end
  end

  describe 'O2OVPE-1037: #inquiry_to_partner' do
    before do
      allow(Channel::Connection::Http).to receive(:post).with(described_class::INQUIRY_URL, any_args).and_return inquiry_response.to_json
    end

    subject { described_class.new(valid_form).inquiry_to_partner }

    context 'when circuit breaker toggle is not active' do
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).and_return(true)
        expect(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(false)
      end

      context 'when RC 00' do
        let(:status) { :success }
        let(:rc) { '00' }

        it 'does not raise error' do
          expect { subject }.not_to raise_error
        end

        it 'returns partner response' do
          expect(subject.customer_name).to eq inquiry_response[:name].rpartition('(').first.strip
        end
      end

      context 'when RC 20' do
        let(:inquiry_response) do
          {
            "desc"          => "Failed",
            "message"       => "Wrong Number / Number Blocked / Number Expired",
            "rc"            => "20",
            "response_code" => "20",
            "status"        => false,
            "trx_id"        => "",
          }
        end
        let(:status) { :fail }
        let(:rc) { '20' }

        it 'does raise error' do
          expect { subject }.to raise_error(::Exceptions::UnregisteredNumber)
        end
      end

      context 'when RC 50' do
        let(:inquiry_response) do
          {
            "desc"          => "Failed",
            "message"       => "Bill Already Paid / Not Yet Available",
            "rc"            => "50",
            "response_code" => "50",
            "status"        => false,
            "trx_id"        => "",
          }
        end
        let(:status) { :fail }
        let(:rc) { '50' }

        it 'does raise error' do
          expect { subject }.to raise_error(::Exceptions::BillAlreadyPaid)
        end
      end

      context 'when RC 21' do
        let(:inquiry_response) do
          {
            "desc"          => "failed",
            "idpel"         => "03050047",
            "message"       => "General Error",
            "rc"            => "21",
            "response_code" => "21",
            "status"        => false,
            "trx_id"        => "",
          }
        end
        let(:status) { :error }
        let(:rc) { '21' }

        it 'does raise error' do
          expect { subject }.to raise_error(::Exceptions::DefaultError)
        end
      end

      context 'when RC 99' do
        let(:inquiry_response) do
          {
            "desc"          => "failed",
            "idpel"         => "03050047",
            "message"       => "General Error",
            "rc"            => "99",
            "response_code" => "99",
            "status"        => false,
            "trx_id"        => "",
          }
        end
        let(:status) { :error }
        let(:rc) { '99' }

        it 'does raise error' do
          expect { subject }.to raise_error(::Exceptions::DefaultError)
        end
      end

      context 'timeout' do
        let(:status) { :timeout }
        let(:rc) { 'error' }

        before do
          allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::OpenTimeout)
        end

        it 'raises timeout error' do
          expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
        end
      end
    end

    context 'when circuit breaker toggle is active' do
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

      context 'when no error' do
        let(:status) { :success }
        let(:rc) { '00' }

        it 'does not raise error' do
          expect { subject }.not_to raise_error
        end

        it 'returns partner response' do
          expect(subject.customer_name).to eq inquiry_response[:name].rpartition('(').first.strip
        end
      end

      context 'when error' do
        it_behaves_like 'expected circuit breaker case', :bpjs_sepulsa_inquiry
      end
    end
  end

  RSpec.shared_examples 'expected payment requests' do
    before do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
    end

    context 'when status pending' do
      let(:status) { :pending }
      let(:rc) { '10' }

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject.partner_transaction_id).to eq payment_response[:transaction_id]
        expect(subject.status).to eq PARTNER_STATUS[SEPULSA][payment_response[:status]]
      end
    end
  end

  describe '#create_transaction' do
    let(:trx) { build(:bpjs_kesehatan_transaction, :with_partner_transaction_id) }

    before do
      allow(Channel::Connection::Http).to receive(:post).with(described_class::TRANSACTION_URL, any_args).and_return payment_response.to_json
    end

    subject { described_class.new(trx).create_transaction }

    context 'when circuit breaker toggle is not active' do
      before do
        expect(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(false)
      end

      it_behaves_like 'expected payment requests'
    end

    context 'when circuit breaker toggle is active' do
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

      context 'when no error' do
        before do
          expect(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(true)
        end
        it_behaves_like 'expected payment requests'
      end

      context 'when error' do
        it_behaves_like 'expected circuit breaker case', :bpjs_sepulsa_transaction
      end
    end
  end

  describe '#confirm_transaction' do
    before do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
    end

    subject { described_class.new(trx).confirm_transaction }

    context 'without partner_transaction_id (request by order_id)' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:trx) { build(:bpjs_kesehatan_transaction) }
      it 'matches the result' do
        allow(Channel::Connection::Http).to receive(:get).with(described_class::TRANSACTION_URL, any_args).and_return get_transaction_by_order_id_response.to_json
        result = subject
        list_item = get_transaction_by_order_id_response[:list][0]
        expect(result.partner_transaction_id).to eq list_item[:transaction_id]
        expect(result.status).to eq PARTNER_STATUS[SEPULSA][list_item[:status]]
      end
    end

    context 'with partner_transaction_id (request by transaction_id)' do
      let(:status) { :success }
      let(:rc) { '00' }
      let(:trx) { build(:bpjs_kesehatan_transaction, :with_partner_transaction_id) }
      it 'matches the result' do
        allow(Channel::Connection::Http).to receive(:get).and_return get_transaction_by_id_response.to_json
        result = subject
        expect(result.partner_transaction_id).to eq get_transaction_by_id_response[:transaction_id]
        expect(result.status).to eq PARTNER_STATUS[SEPULSA][get_transaction_by_id_response[:status]]
      end
    end
  end
end
