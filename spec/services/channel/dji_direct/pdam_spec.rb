require "rails_helper"
include Postpaid::Constant

RSpec.describe Channel::Dji::Pdam, type: :model do
  let(:form) { Form::Pdam.new('01031190018', '192') }
  let(:pdam_operator) { build_stubbed(:pdam_operator, :dji) }

  let(:host) { ENV['DJI_MULTIBILLER_HOST'] }
  let(:port) { ENV['DJI_MULTIBILLER_PORT'] }

  subject { Channel::Dji::Pdam }

  let(:success_inquiry_response) {
    "0210B23840012AC1000C000000000000000238000000000003700001311406180030861406180131900103DJI09bukalapak0000000002710000000001DJI000342      171400021101031191234         0131012020112348NARUTO                        00000003400000000000300020172                                                           SWITCHERID0326A1F04C83A6C9C49D1D2128F3FABE053072201702000000000000000000000000000000000000003000000000000000000000034000003001"
  }

  let(:success_inquiry_response_with_non_tagair) {
    "0210B23840012AC1000C000000000000000238000000000003700001311406180030861406180131900103DJI09bukalapak0000000002710000000001DJI000342      171400021101031191234         0231012020112348NARUTO                        00000003400000000000300020172                                                           SWITCHERID0326A1F04C83A6C9C49D1D2128F3FABE0531420000080000000000000000000000000000000000000250000000000000000000015500002017020000000000000000000000000000000000000030000000000000000000034000003001"
  }

  let(:success_inquiry_response_only_non_tagair) {
    "0210B23840012AC1000C000000000000000238000000000003700001311406180030861406180131900103DJI09bukalapak0000000002710000000001DJI000342      171400021101031191234         0131012020112348NARUTO                        00000003400000000000300020172                                                           SWITCHERID0326A1F04C83A6C9C49D1D2128F3FABE053072000008000000000000000000000000000000000000025000000000000000000001550000003001"
  }

  let(:unregistered_inquiry_response) {
    "0210B23840012AC1000C000000000000000238000000000000000002101443405858751443400210900103DJI09bukalapak0000395858766500000001DJI000342      02940040101100                0003207D798289748E95E740EBF7F97DA42D0038    NOMOR YANG ANDA MASUKAN SALAH     003001"
  }

  let(:failed_inquiry_response) {
    "0210B23840012AC1000C000000000000000238000000000000000002101443405858751443400210900103DJI09bukalapak0000395858766700000001DJI000342      02940040101100                0003207D798289748E95E740EBF7F97DA42D0038    NOMOR YANG ANDA MASUKAN SALAH     003001"
  }

  let(:empty_inquiry_response_code) {
    "0210B23840012AC1000C000000000000000238000000000000000002101443405858751443400210900103DJI09bukalapak000039585876  00000001DJI000342      02940040101100                0003207D798289748E95E740EBF7F97DA42D0038    NOMOR YANG ANDA MASUKAN SALAH     003001"
  }

  let(:bill_already_paid_inquiry_response) {
    "0210B23840012AC1000C000000000000000238000000000000000002111027466035691027460211900103DJI09bukalapak0000396035706400000001DJI000342      029400591016520673            0003281219CAB3F710D03588E8BF1C1A1F31A031    TAGIHAN SUDAH TERBAYAR     003001"
  }

  let(:invalid_date_inquiry_response) {
    "0210B23840012AC1000C000000000000000238000000000003700001311406180030861406180131900103DJI09bukalapak0000000002710000000001DJI000342      171400021101031191234         0131012020112348NARUTO                        00000003400000000000300020170                                                           SWITCHERID0326A1F04C83A6C9C49D1D2128F3FABE053072201713000000000000000000000000000000000000003000000000000000000000034000003001"
  }

  let(:success_payment_response) {
    "0210B23840012AE1000C000000000000000218000000000003750001311406180030861406180131900103DJI09bukalapak0000000002710000000001DJI000342      PT.Bukalapak                            171400021101031191234         0131012020112348NARUTO                        00000003400000000000300020172                                                           SWITCHERID0326A1F04C83A6C9C49D1D2128F3FABE053137201702000000001000000014870000001497Kubah Mangga A2Jl. Candrakasih                                   000000003000000000000000000000034500003001"
  }

  let(:failed_payment_response) {
    "0210B23840012AE1000C000000000000000218000000000005280002101030545789451030540210900103DJI09bukalapak0000395789466400000001DJI000342      PT.Bukalapak                            171400251101031191234         0110022020103008NARUTO                        000000051000000000001800202001                                                          SWITCHERID032314B376A592EBC0CA5E879F72C9E9F99031    TAGIHAN SUDAH TERBAYAR     003001"
  }

  let(:success_confirm_response) {
    "0210B23840012AE1000C000000000000000218000000000003750001311406180030861406180131900103DJI09bukalapak0000000002710000000001DJI000342      PT.Bukalapak                            171400021101031191234         0131012020112348NARUTO                        00000003400000000000300020172                                                           SWITCHERID0326A1F04C83A6C9C49D1D2128F3FABE053137201702000000001000000014870000001497Kubah Mangga A2Jl. Candrakasih                                   000000003000000000000000000000034500003001"
  }

  let(:pending_confirm_response) {
    '0210B23840012AC1000C000000000000000217000000000000000002111331366081141331360211900103DJI09bukalapak0000395789467100000001DJI000342      171400461000112760071         0011022020000000                              000000000000000000000000                                                                000000000003281219CAB3F710D03588E8BF1C1A1F31A029  TRANSAKSI SEDANG DIPROSES  003001'
  }

  let(:failed_confirm_response) {
    '0210B23840012AC1000C000000000000000217000000000000000002111345186083131345180211900103DJI09bukalapak0000395789461700000001DJI000342      17140015100702040172          0010022020000000                              000000000000000000000000                                                                000000000003281219CAB3F710D03588E8BF1C1A1F31A019  TRANSAKSI GAGAL  003001'
  }

  let(:expected_inquiry_result) {
    result = ResponseGeneralizer::Pdam.new
    result.address = "-"
    result.amount = 37000
    result.bills = [ {
      :usage=>"0000000000",
      :start_meter=>0,
      :end_meter=>0,
      :tariff=>0,
      :address=>"-",
      :admin_fee=>3000,
      :penalty_fee=>0,
      :bill_period=> Date.parse("01-02-2017"),
      :amount=>34000,
      :cubication=>"0-0"
      } ]
    result.bukalapak_admin_charge = pdam_operator.bukalapak_admin_charge
    result.partner_admin_charge = pdam_operator.partner_admin_charge
    result.customer_name = 'NARUTO'
    result.customer_number = '01031191234'
    result.end_usage_meter = 0
    result.partner = 'dji'
    result.operator = pdam_operator
    result.penalty_fee = 0
    result.start_bill_period = Date.parse("01-02-2017")
    result.end_bill_period = Date.parse("01-02-2017")
    result.start_usage_meter = 0
    result.usage = 0
    result
  }

  let(:expected_inquiry_result_with_non_tagair) {
    expected_inquiry_result.bills = [
      {
        :usage=>"0000000000",
        :start_meter=>0,
        :end_meter=>0,
        :tariff=>0,
        :address=>"-",
        :admin_fee=>25000,
        :penalty_fee=>0,
        :bill_period=> nil,
        :amount=>1550000,
        :cubication=>"0-0"
      },
      {
        :usage=>"0000000000",
        :start_meter=>0,
        :end_meter=>0,
        :tariff=>0,
        :address=>"-",
        :admin_fee=>3000,
        :penalty_fee=>0,
        :bill_period=> Date.parse("01-02-2017"),
        :amount=>34000,
        :cubication=>"0-0"
      }
    ]
    expected_inquiry_result.bukalapak_admin_charge = pdam_operator.bukalapak_admin_charge * 2
    expected_inquiry_result.partner_admin_charge = pdam_operator.partner_admin_charge * 2
    expected_inquiry_result
  }

  let(:expected_inquiry_result_only_non_tagair) {
    expected_inquiry_result.bills = [
      {
        :usage=>"0000000000",
        :start_meter=>0,
        :end_meter=>0,
        :tariff=>0,
        :address=>"-",
        :admin_fee=>25000,
        :penalty_fee=>0,
        :bill_period=> nil,
        :amount=>1550000,
        :cubication=>"0-0"
      }
    ]

    expected_inquiry_result.start_bill_period = nil
    expected_inquiry_result.end_bill_period = nil
    expected_inquiry_result
  }

  let(:expected_payment_result) {
    result = ResponseGeneralizer::Pdam.new
    result.address = "Jl. Candrakasih"
    result.bills = [{:usage=>"0000000010", :start_meter=>1487, :end_meter=>1497, :tariff=>"Kubah Mangga A2", :address=>"Jl. Candrakasih", :admin_fee=>3000, :penalty_fee=>0, :bill_period=>Date.parse('01-02-2017'), :amount=>34500, :cubication=>"1487-1497"}]
    result.partner_transaction_id = 271
    result.status = SUCCESS
    result
  }

  let(:expected_failed_payment_result) {
    result = ResponseGeneralizer::Pdam.new
    result.partner_transaction_id = 39578946
    result.status = FAILED
    result
  }

  let(:expected_failed_payment_result_without_partner_transaction_id) {
    result = ResponseGeneralizer::Pdam.new
    result.status = FAILED
    result
  }

  let(:expected_confirm_result) {
    expected_payment_result
  }

  let(:expected_failed_confirm_result) {
    expected_failed_payment_result
  }

  let(:pending_confirm_result) {
    result = ResponseGeneralizer::Pdam.new
    result.partner_transaction_id = 39578946
    result.status = PENDING
    result
  }

  def store_rc_to_redis
    expect(RedisOlympus).to receive(:set).with(kind_of(String), anything, hash_including(:ex)).once
  end

  before do
    allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
    allow(Keystore).to receive(:get).with("dji:unique_number").and_return 123456
    allow(Keystore).to receive(:get).with(described_class::SECURITY_NUMBER_KEY).and_return "secretkey123456"

    allow(Toggles::DjiCircuitBreaker).to receive(:active?).and_return true
  end

  describe '.inquiry_to_partner' do
    let(:inquiry_subject) { subject.new(form) }

    context 'when inquiry is success' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_return success_inquiry_response
      end

      it 'returns pdam response generalizer' do
        result = inquiry_subject.inquiry_to_partner
        expect(result).to be_kind_of(ResponseGeneralizer::Pdam)

      end

      it 'returns expected response' do
        result = inquiry_subject.inquiry_to_partner
        expect(result.to_json).to eql(expected_inquiry_result.to_json)
      end
    end

    context 'when inquiry is success with non-tagair bill' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_return success_inquiry_response_with_non_tagair
      end

      it 'returns pdam response generalizer' do
        result = inquiry_subject.inquiry_to_partner
        expect(result).to be_kind_of(ResponseGeneralizer::Pdam)

      end

      it 'returns expected response' do
        result = inquiry_subject.inquiry_to_partner
        expect(result.to_json).to eql(expected_inquiry_result_with_non_tagair.to_json)
      end
    end

    context 'when inquiry fails with invalid date' do
      let(:expected_tags) {%w[olympus pdam dji invalid_date error]}
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_return invalid_date_inquiry_response
      end

      it 'raise ArgumentError' do
        expect { inquiry_subject.inquiry_to_partner }.to raise_error ArgumentError
      end
    end

    context 'when inquiry is success only bill is non-tagair bill' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_return success_inquiry_response_only_non_tagair
      end

      it 'returns pdam response generalizer' do
        result = inquiry_subject.inquiry_to_partner
        expect(result).to be_kind_of(ResponseGeneralizer::Pdam)

      end

      it 'returns expected response' do
        result = inquiry_subject.inquiry_to_partner
        expect(result.to_json).to eql(expected_inquiry_result_only_non_tagair.to_json)
      end
    end

    context 'when inquiry is failed' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_return unregistered_inquiry_response

        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success, operator_id: anything).and_return(autoswitch_instance)
        expect(autoswitch_instance).to receive(:run!).and_return true
      end

      it 'raise unregistered number exception' do
        expect { inquiry_subject.inquiry_to_partner }.to raise_error Exceptions::UnregisteredNumber
      end
    end

    context 'when inquiry is failed and listed in failed partner rc' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_return failed_inquiry_response

        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed, operator_id: anything).and_return(autoswitch_instance)
        expect(autoswitch_instance).to receive(:run!).and_return true
      end

      it 'raise transaction cannot be done exception' do
        expect { inquiry_subject.inquiry_to_partner }.to raise_error Exceptions::TransactionCannotBeDone
      end
    end

    context 'when inquiry is timed out' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_raise Exceptions::SocketConnectionTimeout

        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed, operator_id: anything).and_return(autoswitch_instance)
        expect(autoswitch_instance).to receive(:run!).and_return true
      end

      it 'raise timed out exception' do
        expect { inquiry_subject.inquiry_to_partner }.to raise_error Exceptions::SocketConnectionTimeout
      end
    end
  end

  describe '.create_transaction' do
    let(:pdam_paid_transaction) { create(:pdam_transaction_with_bill) }
    let(:payment_subject) { subject.new(pdam_paid_transaction) }

    context 'when inquiry is success' do
      before do
        allow_any_instance_of(subject).to receive(:inquiry).and_return(Iso8583::Dji.decode(success_inquiry_response))
        store_rc_to_redis
      end

      context 'when payment is success' do
        before do
          allow(Channel::Connection::Iso8583).to receive(:send).and_return success_payment_response
        end

        it 'returns pdam response generalizer with success status' do
          result = payment_subject.create_transaction
          expect(result.to_json).to eq(expected_payment_result.to_json)
        end
      end

      context 'when payment is failed' do
        before do
          allow(Channel::Connection::Iso8583).to receive(:send).and_return failed_payment_response
        end

        it 'returns response generalizer with failed status' do
          result = payment_subject.create_transaction
          expect(result.to_json).to eq(expected_failed_payment_result.to_json)
        end
      end

      context 'when payment is timed out' do
        before do
          allow(Channel::Connection::Iso8583).to receive(:send).and_raise Exceptions::SocketConnectionTimeout
        end

        it 'raises timed out exception' do
          expect { payment_subject.create_transaction }.to raise_error Exceptions::SocketConnectionTimeout
        end
      end
    end

    context 'when inquiry is failed' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_return bill_already_paid_inquiry_response
        
        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success, operator_id: anything).and_return(autoswitch_instance)
        allow(autoswitch_instance).to receive(:run!).and_return true
      end

      it 'returns response generalizer with failed status' do
        result = payment_subject.create_transaction
        expect(result.to_json).to eq(expected_failed_payment_result_without_partner_transaction_id.to_json)
      end
    end

    context 'when inquiry is timed out' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_raise Exceptions::SocketConnectionTimeout

        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed, operator_id: anything).and_return(autoswitch_instance)
        expect(autoswitch_instance).to receive(:run!).and_return true
      end

      it 'raises timed out exception and set transaction to paid state' do
        expect { payment_subject.create_transaction }.to raise_error Exceptions::SocketConnectionTimeout
        expect(pdam_paid_transaction.state).to eq 'paid'
      end

      it 'not call create function' do
        expect_any_instance_of(subject).not_to receive(:create)
        payment_subject.create_transaction rescue nil
      end
    end

    context 'when inquiry is connection fail' do
      before do
        allow(Channel::Connection::Iso8583).to receive(:send).and_raise Errno::ETIMEDOUT

        autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed, operator_id: '1')
        allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed, operator_id: anything).and_return(autoswitch_instance)
        expect(autoswitch_instance).to receive(:run!).and_return true
      end

      it 'raises timed out exception and set transaction to paid state' do
        expect { payment_subject.create_transaction }.to raise_error Exceptions::Dji::ErrTimeout
        expect(pdam_paid_transaction.state).to eq 'paid'
      end

      it 'not call create function' do
        expect_any_instance_of(subject).not_to receive(:create)
        payment_subject.create_transaction rescue nil
      end
    end
  end

  describe '.confirm_transaction' do
    context 'when transaction has no partner transaction id' do
      let(:pdam_transaction_without_partner_transaction_id) { create(:pdam_transaction_with_bill, :without_partner_transaction_id) }
      let(:confirm_subject) { subject.new(pdam_transaction_without_partner_transaction_id) }

      it 'should raise error' do
        expect{ confirm_subject.confirm_transaction }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end

    context 'when transaction has partner transaction id' do
      let(:pdam_transaction_processed) { create(:pdam_transaction_with_bill, :processed) }
      let(:confirm_subject) { subject.new(pdam_transaction_processed) }

      context 'when get success response confirm' do
        before do
          allow(Channel::Connection::Iso8583).to receive(:send).and_return success_confirm_response
        end

        it 'returns response response generalizer PDAM with success status' do
          result = confirm_subject.confirm_transaction
          expect(result.to_json).to eq(expected_confirm_result.to_json)
        end
      end

      context 'when get pending response confirm' do
        before do
          allow(Channel::Connection::Iso8583).to receive(:send).and_return pending_confirm_response
        end

        it 'returns response generalizer PDAM with pending status' do
          result = confirm_subject.confirm_transaction
          expect(result.to_json).to eq(pending_confirm_result.to_json)
        end
      end

      context 'when get failed response confirm' do
        before do
          allow(Channel::Connection::Iso8583).to receive(:send).and_return failed_confirm_response
        end

        it 'returns response generalizer PDAM with failed status' do
          result = confirm_subject.confirm_transaction
          expect(result.to_json).to eq(expected_failed_confirm_result.to_json)
        end
      end
    end
  end
end
