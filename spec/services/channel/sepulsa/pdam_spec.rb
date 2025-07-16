require "rails_helper"

RSpec.describe Channel::Sepulsa::Pdam, type: :model do
  include ::Postpaid::Constant

  let(:customer_number) { "1998900001" }
  let(:pdam_operator) { build_stubbed(:pdam_operator)}
  let(:valid_operator_id) { pdam_operator.id }
  let(:invalid_operator_id) { 989881 }
  let(:valid_form) { Form::Pdam.new(customer_number, valid_operator_id) }
  let(:invalid_form) { Form::Pdam.new(customer_number, invalid_operator_id) }
  # let(:inquiry_response) {
  #   {
  #     idpel: '1998900001',
  #     name: 'JUNAIDI XX001                 ',
  #     amount: 11110,
  #     admin_charge: 0,
  #     blth: "201201201201",
  #     bill_count: '01',
  #     bill_repeat_count: '01',
  #     bills: [
  #       {
  #         bill_date: ['201201'],
  #         bill_amount: ['000000011110'],
  #         penalty: ["00000000"],
  #         kubikasi: ["00000402-00000458"]
  #       }
  #     ]
  #   }
  # }
  let(:inquiry_response) {
    {
      "stan": "1910133159",
      "amount": "129890",
      "transmission_datetime": "1599603675",
      "merchant_code": "6021",
      "local_trx_time": "222115",
      "local_trx_date": "20200908",
      "acquiring_institution_id": "000",
      "admin_charge": "0",
      "mti": "0210",
      "pan": "",
      "processing_code": "",
      "settlement_date": "20200909",
      "retrieval_ref_no": "1910133159",
      "blth": "202008202008",
      "name": "Covid Bryant",
      "bill_count": "1",
      "bill_repeat_count": "1",
      "rp_tag": "129890",
      "customer_address": "",
      "group_code": "",
      "group_desc": "",
      "bills": [
        {
          "bill_date": [
            "202008"
          ],
          "kubikasi": [
            "42-74"
          ],
          "penalty": [
            "0"
          ],
          "bill_amount": [
            "129890"
          ],
          "waterusage_bill": "",
          "total_fee": "",
          "detail_fee": {
            "pdam_fee": "",
            "maintenance_fee": "",
            "retribution_fee": "",
            "wastewater_fee": "",
            "service_fee": "",
            "stamp_fee": "",
            "reconnection_fee": "",
            "nonwater_fee": "",
            "installment_amount": "",
            "seal_penalty": "",
            "lltt_fee": "",
            "gwt": "",
            "vat": ""
          },
          "lift_usage": "",
          "total_usage": "",
          "detail_usage": {
            "usage1": "",
            "usage2": "",
            "usage3": "",
            "usage4": ""
          },
          "info_text": ""
        }
      ],
      "status": true,
      "response_code": "00",
      "rc": "00",
      "trx_id": "",
      "idpel": "03991296"
    }
  }
  let(:payment_response) {
    {
      "amount": "67640",
      "customer_number": "12312312",
      "serial_number": nil,
      "response_code": "10",
      "status": "pending",
      "order_id": "PDM-1231231231",
      "operator_code": "pdam_kota_semarang",
      "transaction_id": "123123123",
      "price": "69940",
      "token": nil,
      "type": "pdam",
      "changed": "1599569291",
      "created": "1599569291",
      "data": nil,
      "product_id": {
        "operator": "pdam kota semarang",
        "nominal": "0",
        "price": 2300,
        "enabled": "1",
        "label": "PDAM KOTA SEMARANG (JATENG)",
        "type": "pdam",
        "product_id": "978"
      }
    }
  }
  let(:get_transaction_by_order_id_response) {
    {
      "self": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=PDM-234234234",
      "first": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=PDM-234234234\\u0026page=1",
      "last": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=PDM-234234234\\u0026page=1",
      "list": [
        {
          "transaction_id": "234",
          "type": "pdam",
          "created": "1599574799",
          "changed": "1599574800",
          "customer_number": "06620183",
          "product_id": {
            "product_id": "978",
            "type": "pdam",
            "label": "PDAM KOTA SEMARANG (JATENG)",
            "operator": "pdam kota semarang",
            "nominal": "0",
            "price": 2300,
            "enabled": "1"
          },
          "order_id": "PDM-234234234",
          "price": "73260",
          "status": "success",
          "response_code": "00",
          "serial_number": "1910103141",
          "amount": "70960",
          "token": nil,
          "data": {
            "trx_id": "123",
            "stan": "1910103141",
            "amount": "70960",
            "datetime": "1599574799000",
            "merchant_code": "6021",
            "rc": "00",
            "local_trx_time": "120320",
            "local_trx_date": "526580705",
            "acquiring_institution_id": "000",
            "admin_charge": "0",
            "biller_ref": "1910103141",
            "settlement_date": "526580706",
            "retrieval_ref_no": "1910103141",
            "switching_ref": "1910103141",
            "idpel": "06620183",
            "blth": "202008202008",
            "name": "Rona Corona",
            "bill_count": "1",
            "bill_repeat_count": "1",
            "rp_tag": "70960",
            "waktu_lunas": "20200908211959",
            "customer_address": "",
            "group_code": "",
            "group_desc": "",
            "bills": [
              {
                "bill_date": [
                  "202008"
                ],
                "kubikasi": [
                  "1269-1287"
                ],
                "penalty": [
                  "0"
                ],
                "bill_amount": [
                  "70960"
                ],
                "waterusage_bill": "",
                "total_fee": "",
                "detail_fee": {
                  "pdam_fee": "",
                  "maintenance_fee": "",
                  "retribution_fee": "",
                  "wastewater_fee": "",
                  "service_fee": "",
                  "stamp_fee": "",
                  "reconnection_fee": "",
                  "nonwater_fee": "",
                  "installment_amount": "",
                  "seal_penalty": "",
                  "lltt_fee": "",
                  "gwt": "",
                  "vat": ""
                },
                "lift_usage": "",
                "total_usage": "",
                "detail_usage": {
                  "usage1": "",
                  "usage2": "",
                  "usage3": "",
                  "usage4": ""
                },
                "info_text": ""
              }
            ]
          },
          "operator_code": "pdam_kota_semarang"
        }
      ]
    }
  }
  let(:get_transaction_by_id_response) {
    {
      "transaction_id": "345",
      "type": "pdam",
      "created": "1599574799",
      "changed": "1599574800",
      "customer_number": "06620183",
      "product_id": {
        "product_id": "978",
        "type": "pdam",
        "label": "PDAM KOTA SEMARANG (JATENG)",
        "operator": "pdam kota semarang",
        "nominal": "0",
        "price": 2300,
        "enabled": "1"
      },
      "order_id": "PDM-345345345",
      "price": "73260",
      "status": "success",
      "response_code": "00",
      "serial_number": "1910103141",
      "amount": "70960",
      "token": nil,
      "data": {
        "trx_id": "345",
        "stan": "1910103141",
        "amount": "70960",
        "datetime": "1599574799000",
        "merchant_code": "6021",
        "rc": "00",
        "local_trx_time": "120320",
        "local_trx_date": "526580705",
        "acquiring_institution_id": "000",
        "admin_charge": "0",
        "biller_ref": "1910103141",
        "settlement_date": "526580706",
        "retrieval_ref_no": "1910103141",
        "switching_ref": "1910103141",
        "idpel": "06620183",
        "blth": "202008202008",
        "name": "Rona Corona",
        "bill_count": "1",
        "bill_repeat_count": "1",
        "rp_tag": "70960",
        "waktu_lunas": "20200908211959",
        "customer_address": "",
        "group_code": "",
        "group_desc": "",
        "bills": [
          {
            "bill_date": [
              "202008"
            ],
            "kubikasi": [
              "1269-1287"
            ],
            "penalty": [
              "0"
            ],
            "bill_amount": [
              "70960"
            ],
            "waterusage_bill": "",
            "total_fee": "",
            "detail_fee": {
              "pdam_fee": "",
              "maintenance_fee": "",
              "retribution_fee": "",
              "wastewater_fee": "",
              "service_fee": "",
              "stamp_fee": "",
              "reconnection_fee": "",
              "nonwater_fee": "",
              "installment_amount": "",
              "seal_penalty": "",
              "lltt_fee": "",
              "gwt": "",
              "vat": ""
            },
            "lift_usage": "",
            "total_usage": "",
            "detail_usage": {
              "usage1": "",
              "usage2": "",
              "usage3": "",
              "usage4": ""
            },
            "info_text": ""
          }
        ]
      },
      "operator_code": "pdam_kota_semarang"
    }
  }
  let(:form_channel) { Channel::Sepulsa::Pdam }

  before do
    allow(Toggles::SepulsaMitraAuth).to receive(:active?).and_return true
  end

  context "invalid payment period" do
    it "should raise error" do
      expect { form_channel.new(invalid_form) }.to raise_error(::Exceptions::InvalidPdamOperator)
    end
  end

  describe '#get_auth' do
    subject { described_class.new(valid_form) }

    before(:each) do
      allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
    end

    it 'return normal auth' do
      expect(subject.get_auth).to eq(described_class::AUTH)
    end

    context 'when buyer is mitra' do
      let(:valid_form) { Form::Pdam.new(customer_number, valid_operator_id, nil, AGENT_BUYER_TYPE) }

      it 'return mitra auth' do
        expect(subject.get_auth).to eq(described_class::MITRA_AUTH)
      end
    end
  end

  describe '#inquiry_to_partner' do
    # it "should not raise error" do
    #   allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
    #   allow_any_instance_of(form_channel).to receive(:inquiry).and_return(inquiry_response)
    #   expect { form_channel.new(valid_form).inquiry_to_partner }.not_to raise_error
    # end

    subject { described_class.new(valid_form).inquiry_to_partner }

    before {
      allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
      # allow(Action::PostpaidTransaction::Inquiry).to receive(:record_inquiry_autoswitch_value).and_return(nil)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
    }

    context 'when RC 00' do
      let(:status) { :success }
      let(:rc) { '00' }

      before do
        allow(Channel::Connection::Http).to receive(:post).with(described_class::INQUIRY_URL, any_args).and_return inquiry_response.to_json
        
        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success, operator_id: anything).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true
      end

      it {
        expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
        expect { subject }.not_to raise_error
      }
    end

    context 'when RC 20' do
      let(:inquiry_response) {
        {
          "desc"          => "Failed",
          "message"       => "Wrong Number / Number Blocked / Number Expired",
          "rc"            => "20",
          "response_code" => "20",
          "status"        => false,
          "trx_id"        => "",
        }
      }
      let(:status) { :fail }
      let(:rc) { '20' }

      before do
        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success, operator_id: anything).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true
      end

      it {
        expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
        allow(Channel::Connection::Http).to receive(:post).with(described_class::INQUIRY_URL, any_args).and_return inquiry_response.to_json
        expect { subject }.to raise_error(::Exceptions::UnregisteredNumber)
      }
    end

    context 'when RC 50' do
      let(:inquiry_response) {
        {
          "desc"          => "Failed",
          "message"       => "Bill Already Paid / Not Yet Available",
          "rc"            => "50",
          "response_code" => "50",
          "status"        => false,
          "trx_id"        => "",
        }
      }
      let(:status) { :fail }
      let(:rc) { '50' }

      before do
        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success, operator_id: anything).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true
      end

      it {
        expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
        allow(Channel::Connection::Http).to receive(:post).with(described_class::INQUIRY_URL, any_args).and_return inquiry_response.to_json
        expect { subject }.to raise_error(::Exceptions::BillAlreadyPaid)
      }
    end

    context 'when RC 99' do
      let(:inquiry_response) {
        {
          "desc"          => "failed",
          "idpel"         => "03050047",
          "message"       => "General Error",
          "rc"            => "99",
          "response_code" => "99",
          "status"        => false,
          "trx_id"        => "",
        }
      }
      let(:status) { :error }
      let(:rc) { '99' }

      before do
        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed, operator_id: anything).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true
      end

      it {
        expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
        allow(Channel::Connection::Http).to receive(:post).with(described_class::INQUIRY_URL, any_args).and_return inquiry_response.to_json
        expect { subject }.to raise_error(::Exceptions::DefaultError)
      }
    end
  end

  describe '#create_transaction' do
    let(:status) { :pending }
    let(:rc) { '10' }
    let(:trx) { build(:pdam_transaction_with_bill) }
    subject { described_class.new(trx).create_transaction }
    it 'matches the result' do
      expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
      expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
      allow(Channel::Connection::Http).to receive(:post).with(described_class::TRANSACTION_URL, any_args).and_return payment_response.to_json
      result = subject
      expect(result.partner_transaction_id).to eq payment_response[:transaction_id]
      expect(result.status).to eq PARTNER_STATUS[SEPULSA][payment_response[:status]]
    end
  end

  describe '#confirm_transaction' do
    subject { described_class.new(trx).confirm_transaction }

    before do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
    end

    context 'without partner_transaction_id (request by order_id)' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:trx) { build(:pdam_transaction_with_bill, :without_partner_transaction_id)}
      it 'matches the result' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
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
      let(:trx) { build(:pdam_transaction_with_bill) }
      it 'matches the result' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        allow(Channel::Connection::Http).to receive(:get).and_return get_transaction_by_id_response.to_json
        result = subject
        expect(result.partner_transaction_id).to eq get_transaction_by_id_response[:transaction_id]
        expect(result.status).to eq PARTNER_STATUS[SEPULSA][get_transaction_by_id_response[:status]]
      end
    end

    context 'timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }
      let(:trx) { build(:pdam_transaction_with_bill) }
      it 'matches the result' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        allow(Channel::Connection::Http).to receive(:get).and_raise(RestClient::Exceptions::OpenTimeout)
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end
  end
end
