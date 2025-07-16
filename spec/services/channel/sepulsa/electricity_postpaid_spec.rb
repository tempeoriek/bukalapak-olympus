require "rails_helper"

RSpec.describe Channel::Sepulsa::ElectricityPostpaid, type: :model do
  let(:customer_number) {"512345600003"}
  let(:form) { Form::ElectricityPostpaid.new(customer_number) }
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  let(:inquiry_response) {
    {
      "datetime"                => "20200909101418",
      "amount"                  => "173750",
      "stan"                    => "660425644754",
      "admin_charge"            => "8250",
      "merchant_code"           => "6021",
      "bank_code"               => "4510017",
      "terminal_id"             => "0000000000000048",
      "subscriber_id"           => "512345600003",
      "subscriber_name"         => "WISHNU EKA SIDHARTA",
      "switcher_refno"          => "N38UCO77WK803B0VGBXA7T4M6KAG51RV",
      "subscriber_segmentation" => "R1",
      "power"                   => 900,
      "outstanding_bill"        => "0",
      "bill_status"             => "3",
      "blth_summary"            => "JUL20, AUG20, SEP20",
      "stand_meter_summary"     => "00027135 - 00027588",
      "bills" => [
        {
          "produk"                  => "PLNPOSTPAID",
          "bill_period"             => "202007",
          "due_date"                => "20200710",
          "meter_read_date"         => "00000000",
          "total_electricity_bill"  => "44500",
          "incentive"               => "00000000000",
          "value_added_tax"         => "0000000000",
          "penalty_fee"             => "000016000",
          "previous_meter_reading1" => "00027135",
          "current_meter_reading1"  => "00027286",
          "previous_meter_reading2" => "00000000",
          "current_meter_reading2"  => "00000000",
          "previous_meter_reading3" => "00000000",
          "current_meter_reading3"  => "00000000"
        },
        {
          "produk"                  => "PLNPOSTPAID",
          "bill_period"             => "202008",
          "due_date"                => "20200810",
          "meter_read_date"         => "00000000",
          "total_electricity_bill"  => "44500",
          "incentive"               => "00000000000",
          "value_added_tax"         => "0000000000",
          "penalty_fee"             => "000016000",
          "previous_meter_reading1" => "00027286",
          "current_meter_reading1"  => "00027437",
          "previous_meter_reading2" => "00000000",
          "current_meter_reading2"  => "00000000",
          "previous_meter_reading3" => "00000000",
          "current_meter_reading3"  => "00000000"
        },
        {
          "produk"                  => "PLNPOSTPAID",
          "bill_period"             => "202009",
          "due_date"                => "20200910",
          "meter_read_date"         => "00000000",
          "total_electricity_bill"  => "44500",
          "incentive"               => "00000000000",
          "value_added_tax"         => "0000000000",
          "penalty_fee"             => "00000000000",
          "previous_meter_reading1" => "00027437",
          "current_meter_reading1"  => "00027588",
          "previous_meter_reading2" => "00000000",
          "current_meter_reading2"  => "00000000",
          "previous_meter_reading3" => "00000000",
          "current_meter_reading3"  => "00000000"
        }
      ],
      "material_number" => "",
      "status"          => true,
      "response_code"   => "00",
      "rc"              => "00",
      "trx_id"          => ""
    }.with_indifferent_access
  }
  let(:payment_response) {
    {
      "transaction_id"          => "142294",
      "type"                    => "electricity_postpaid",
      "created"                 => "1599621290",
      "changed"                 => "1599621290",
      "customer_number"         => "512345600003",
      "product_id"              => {
        "product_id" => "80",
        "label"      => "PLN POSTPAID",
        "operator"   => "PLN Postpaid",
        "nominal"    => "0",
        "price"      => 2750,
        "enabled"    => "1"
      },
      "order_id"      => "ELP-1374318",
      "price"         => "173750",
      "status"        => "pending",
      "response_code" => "10",
      "serial_number" => nil,
      "amount"        => "165500",
      "token"         => nil,
      "data"          => {
        "subscriber_segmentation" => "R1M",
        "power"                   => 900,
        "stand_meter_summary"     => "00047824 - 000048084",
      }
    }.with_indifferent_access
  }

  let(:get_transaction_by_order_id_response) {
    {
      "self": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=ELP-5364977608",
      "first": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=ELP-5364977608\\u0026page=1",
      "last": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=ELP-5364977608\\u0026page=1",
      "list": [
        {
          "transaction_id": "140064735",
          "type": "electricity_postpaid",
          "created": "1597800012",
          "changed": "1597800012",
          "customer_number": "512345600003",
          "product_id": {
            "product_id": "189",
            "type": "electricity_postpaid",
            "label": "PLN Postpaid",
            "operator": "PLN POSTPAID",
            "nominal": "2500",
            "price": 2500,
            "enabled": "1"
          },
          "order_id": "ELP-5364977608",
          "price": "37900",
          "status": "success",
          "response_code": "00",
          "serial_number": "045421CB6A4D60B0C8E0E8C57823112F",
          "amount": "35400",
          "token": nil,
          "data": {
            "payment_status": "1",
            "pln_refno": "",
            "service_unit": "00000",
            "service_unit_phone": "000000000000000",
            "datetime": "20200819082012",
            "payment_date": "",
            "payment_time": "",
            "info_text": "\"Informasi Hubungi Call Center 123 Atau Hub PLN Terdekat :\".",
            "amount": "37900",
            "stan": "007620133444",
            "admin_charge": "2500",
            "merchant_code": "6021",
            "bank_code": "4410010",
            "terminal_id": "1391013909607231",
            "subscriber_id": "512345600003",
            "subscriber_name": "GEREJA",
            "switcher_refno": "045421CB6A4D60B0C8E0E8C57823112F",
            "subscriber_segmentation": "S2",
            "power": 450,
            "outstanding_bill": "0",
            "bill_status": "1",
            "blth_summary": "AGU20",
            "stand_meter_summary": "00026735 - 00026861",
            "bills": [
              {
                "produk": [
                  "PLNPOSTPAID"
                ],
                "bill_period": [
                  "202008"
                ],
                "due_date": [
                  "01082020"
                ],
                "meter_read_date": [
                  "00000000"
                ],
                "total_electricity_bill": [
                  "000000035400"
                ],
                "incentive": [
                  "00000000000"
                ],
                "value_added_tax": [
                  "0000000000"
                ],
                "penalty_fee": [
                  "000000000000"
                ],
                "previous_meter_reading1": [
                  "00026735"
                ],
                "current_meter_reading1": [
                  "00026861"
                ],
                "previous_meter_reading2": [
                  "00000000"
                ],
                "current_meter_reading2": [
                  "00000000"
                ],
                "previous_meter_reading3": [
                  "00000000"
                ],
                "current_meter_reading3": [
                  "00000000"
                ]
              }
            ],
            "trx_id": "",
            "rc": "00",
            "material_number": "",
            "rptag": "35400"
          }
        }
      ]
    }.with_indifferent_access
  }
  let(:get_transaction_by_id_response) {
    {
      "transaction_id": "140064735",
      "type": "electricity_postpaid",
      "created": "1597800012",
      "changed": "1597800012",
      "customer_number": "512345600003",
      "product_id": {
        "product_id": "189",
        "type": "electricity_postpaid",
        "label": "PLN Postpaid",
        "operator": "PLN POSTPAID",
        "nominal": "2500",
        "price": 2500,
        "enabled": "1"
      },
      "order_id": "ELP-5364977608",
      "price": "37900",
      "status": "success",
      "response_code": "00",
      "serial_number": "045421CB6A4D60B0C8E0E8C57823112F",
      "amount": "35400",
      "token": nil,
      "data": {
        "payment_status": "1",
        "pln_refno": "",
        "service_unit": "00000",
        "service_unit_phone": "000000000000000",
        "datetime": "20200819082012",
        "payment_date": "",
        "payment_time": "",
        "info_text": "\"Informasi Hubungi Call Center 123 Atau Hub PLN Terdekat :\".",
        "amount": "37900",
        "stan": "007620133444",
        "admin_charge": "2500",
        "merchant_code": "6021",
        "bank_code": "4410010",
        "terminal_id": "1391013909607231",
        "subscriber_id": "512345600003",
        "subscriber_name": "GEREJA",
        "switcher_refno": "045421CB6A4D60B0C8E0E8C57823112F",
        "subscriber_segmentation": "S2",
        "power": 450,
        "outstanding_bill": "0",
        "bill_status": "1",
        "blth_summary": "AGU20",
        "stand_meter_summary": "00026735 - 00026861",
        "bills": [
          {
            "produk": [
              "PLNPOSTPAID"
            ],
            "bill_period": [
              "202008"
            ],
            "due_date": [
              "01082020"
            ],
            "meter_read_date": [
              "00000000"
            ],
            "total_electricity_bill": [
              "000000035400"
            ],
            "incentive": [
              "00000000000"
            ],
            "value_added_tax": [
              "0000000000"
            ],
            "penalty_fee": [
              "000000000000"
            ],
            "previous_meter_reading1": [
              "00026735"
            ],
            "current_meter_reading1": [
              "00026861"
            ],
            "previous_meter_reading2": [
              "00000000"
            ],
            "current_meter_reading2": [
              "00000000"
            ],
            "previous_meter_reading3": [
              "00000000"
            ],
            "current_meter_reading3": [
              "00000000"
            ]
          }
        ],
        "trx_id": "",
        "rc": "00",
        "material_number": "",
        "rptag": "35400"
      }
    }
  }

  before do
    allow(Toggles::SepulsaMitraAuth).to receive(:active?).and_return true
  end

  describe '#get_auth' do
    subject { described_class.new(form) }

    it 'return normal auth' do
      expect(subject.get_auth).to eq(described_class::AUTH)
    end

    context 'when buyer is mitra' do
      let(:form) { Form::ElectricityPostpaid.new(customer_number, nil, nil, AGENT_BUYER_TYPE) }

      it 'return mitra auth' do
        expect(subject.get_auth).to eq(described_class::MITRA_AUTH)
      end
    end
  end

  describe '#inquiry_to_partner' do
    subject { described_class.new(form).inquiry_to_partner }

    before {
      allow(Time.zone).to receive(:now).and_return(Time.parse("01:01"))
      allow(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
      allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
    }

    context 'when closed time' do
      before {
        allow(Time.zone).to receive(:now).and_return(Time.parse("23:00"))
      }
      it {
        expect { subject }.to raise_error(::Exceptions::ClosedTimeError)
      }
    end

    context 'when RC 00' do
      let(:status) { :success }
      let(:rc) { '00' }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).and_return(true)
        expect(RedisOlympus).to receive(:set).with(kind_of(String), "00", hash_including(:ex))
        allow(Channel::Connection::Http).to receive(:post).with(described_class::INQUIRY_URL, any_args).and_return inquiry_response.to_json

        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true
      end

      it do
        expect { subject }.not_to raise_error
      end
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
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).and_return(true)
        expect(RedisOlympus).to receive(:set).with(kind_of(String), "20", hash_including(:ex))
        allow(Channel::Connection::Http).to receive(:post).with(described_class::INQUIRY_URL, any_args).and_return inquiry_response.to_json

        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true
      end

      it do
        expect { subject }.to raise_error(::Exceptions::UnregisteredNumber)
      end
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
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).and_return(true)
        expect(RedisOlympus).to receive(:set).with(kind_of(String), "50", hash_including(:ex))
        allow(Channel::Connection::Http).to receive(:post).with(described_class::INQUIRY_URL, any_args).and_return inquiry_response.to_json

        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true
      end

      it do
        expect { subject }.to raise_error(::Exceptions::BillAlreadyPaid)
      end
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
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).and_return(true)
        expect(RedisOlympus).to receive(:set).with(kind_of(String), "99", hash_including(:ex))
        allow(Channel::Connection::Http).to receive(:post).with(described_class::INQUIRY_URL, any_args).and_return inquiry_response.to_json

        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true
      end

      it {
        expect { subject }.to raise_error(::Exceptions::DefaultError)
      }
    end
  end

  describe '#create_transaction' do
    let(:trx) { build(:postpaid_transaction_with_bill) }
    let(:status) { :pending }
    let(:rc) { '10' }

    subject { described_class.new(trx).create_transaction }
    it 'matches the result' do
      expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
      expect(RedisOlympus).to receive(:set).with(kind_of(String), "10", hash_including(:ex))
      allow(Channel::Connection::Http).to receive(:post).with(described_class::TRANSACTION_URL, any_args).and_return payment_response.to_json
      result = subject
      expect(result.partner_transaction_id).to eq payment_response[:transaction_id]
      expect(result.status).to eq PARTNER_STATUS[SEPULSA][payment_response[:status]]
      expect(result.power).to eq payment_response[:data][:power]
      expect(result.stand_meter).to eq payment_response[:data][:stand_meter_summary]
      expect(result.segmentation).to eq payment_response[:data][:subscriber_segmentation]
    end
  end

  describe '#confirm_transaction' do
    subject { described_class.new(trx).confirm_transaction }

    context 'without partner_transaction_id (request by order_id)' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:trx) { build(:postpaid_transaction_with_bill, :without_partner_transction_id)}
      it 'matches the result' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).and_return(true)
        expect(RedisOlympus).not_to receive(:set)
        allow(Channel::Connection::Http).to receive(:get).with(described_class::TRANSACTION_URL, any_args).and_return get_transaction_by_order_id_response.to_json
        result = subject
        list_item = get_transaction_by_order_id_response[:list][0]
        expect(result.partner_transaction_id).to eq list_item[:transaction_id]
        expect(result.status).to eq PARTNER_STATUS[SEPULSA][list_item[:status]]
        expect(result.power).to eq list_item[:data][:power].to_i
        expect(result.stand_meter).to eq list_item[:data][:stand_meter_summary]
        expect(result.segmentation).to eq list_item[:data][:subscriber_segmentation]
      end
    end

    context 'with partner_transaction_id (request by transaction_id)' do
      let(:status) { :success }
      let(:rc) { '00' }
      let(:trx) { build(:postpaid_transaction_with_bill) }
      it 'matches the result' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).and_return(true)
        allow(Channel::Connection::Http).to receive(:get).and_return get_transaction_by_id_response.to_json
        result = subject
        expect(result.partner_transaction_id).to eq get_transaction_by_id_response[:transaction_id]
        expect(result.status).to eq PARTNER_STATUS[SEPULSA][get_transaction_by_id_response[:status]]
        expect(result.power).to eq get_transaction_by_id_response[:data][:power].to_i
        expect(result.stand_meter).to eq get_transaction_by_id_response[:data][:stand_meter_summary]
        expect(result.segmentation).to eq get_transaction_by_id_response[:data][:subscriber_segmentation]
      end
    end
  end

end
