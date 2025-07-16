require "rails_helper"
include Postpaid::Constant

RSpec.describe Channel::Dji::BpjsKesehatan, type: :model do
  let(:form) { Form::BpjsKesehatan.new('8888801306460946', '01') }
  let(:bpjs_kesehatan_transaction) { build_stubbed(:bpjs_kesehatan_transaction, :processed) }
  let(:bpjs_kesehatan_transaction_with_partner_transaction_id) { build_stubbed(:bpjs_kesehatan_transaction, :processed, :with_partner_transaction_id) }
  let(:host) { ENV['DJI_MULTIBILLER_HOST'] }
  let(:port) { ENV['DJI_MULTIBILLER_PORT'] }

  subject { Channel::Dji::BpjsKesehatan }

  let(:success_inquiry_response) {
    response = "0210B23840012AC1000C000000000000000238000000000005350001301429432341571429430130900103DJI09bukalapak0000000000200000000001DJI000342      17190000108888801381184572    0130012019143501untung basuki                 000000051000000000002500                                                                06        032F5E3E07D01351F7F1EEED505B3CD9FB42258888801381184572    BEKASI                        0128988801381184572    untung basuki                 0000000255000000000000008988801381185764    erlin dwi meiriska            000000025500000000000000000000002500000000053500003001"
    Iso8583::Dji.decode(response)
  }

  let(:success_payment_response) {
    response = "0210B23840012AE1000C000000000000010218000000000005350001302018060101292018060130900103DJI09bukalapak0000000000230000000001DJI000342      PT.Bukalapak                            17190000108888801381184572    0130012019202325untung basuki                 0000000510000000000025006018C85EE675F68D                                                06        032F5E3E07D01351F7F1EEED505B3CD9FB42218888801381184572    untung basuki                 6018C85EE675F68D                201000000051000000000002500000000053500                                                                                                    01462812356214783003001"
    Iso8583::Dji.decode(response)
  }

  let(:failed_payment_response) {
    response = "0210B23840012AE1000C000000000000010218000000000020650005021352297696511352290502900103DJI09bukalapak0000003108977000000001DJI000342      PT.Bukalapak                            17190000108888802461388782    0102052019135228SUHARTONO                     000000408000000000002500 888880246138878201 00000000                                    06        032436FFDBF2BB65D84B4EB64791941B269028  NOMINAL PEMBAYARAN SALAH  012628562842085003001"
    Iso8583::Dji.decode(response)
  }

  let(:expected_inquiry_result) {
    result = ResponseGeneralizer::BpjsKesehatan.new
    result.customer_number = '8888801381184572'
    result.customer_name = 'untung basuki'
    result.amount = 53500
    result.bukalapak_admin_charge = bpjs_kesehatan_transaction.partner_object.bukalapak_admin_charge
    result.partner_admin_charge = bpjs_kesehatan_transaction.partner_object.partner_admin_charge
    result.family_member_count = 2
    result.family_members = [
      {
        :member_number=>"8988801381184572",
        :name=>"untung basuki",
        :balance=>0,
        :premium=>25500
      },
      {
        :member_number=>"8988801381185764",
        :name=>"erlin dwi meiriska",
        :balance=>0,
        :premium=>25500
      }
    ]

    result.payment_period = '01'
    result.branch_name = 'BEKASI'
    result.partner = 'dji-bpjs'
    result.paid_until = {
      month: form.month,
      year: form.year
    }
    result
  }

  let(:expected_payment_result) {
    result = ResponseGeneralizer::BpjsKesehatan.new
    result.reference_number = '6018C85EE675F68D'
    result.info = ''
    result.partner_transaction_id = '23'
    result.status = 2

    result
  }

  let(:expected_failed_payment_result) {
    result = ResponseGeneralizer::BpjsKesehatan.new
    result.partner_transaction_id = '310897'
    result.status = 3

    result
  }
  before do
    allow(BpjsKesehatanPartner).to receive(:find_by).and_return(build_stubbed(:bpjs_kesehatan_partner))
    allow(Keystore).to receive(:get).with("dji:unique_number").and_return 123456
    allow(Keystore).to receive(:get).with(described_class::SECURITY_NUMBER_KEY).and_return "secretkey123456"
  end

  describe '.inquiry_to_partner' do
    let(:inquiry_subject) { subject.new(form) }

    context 'when inquiry is success' do
      before do
        expect_any_instance_of(Channel::Dji::BpjsKesehatan).to receive(:inquiry).and_return success_inquiry_response
      end

      it 'does not raise error' do
        expect { inquiry_subject.inquiry_to_partner }.not_to raise_error
      end

      it 'returns correct value' do
        result = inquiry_subject.inquiry_to_partner
        expect(result).to be_kind_of(ResponseGeneralizer::BpjsKesehatan)
        expect(result.customer_number).to eq expected_inquiry_result.customer_number
        expect(result.customer_name).to eq expected_inquiry_result.customer_name
        expect(result.amount).to eq expected_inquiry_result.amount
        expect(result.bukalapak_admin_charge).to eq expected_inquiry_result.bukalapak_admin_charge
        expect(result.partner_admin_charge).to eq expected_inquiry_result.partner_admin_charge
        expect(result.family_member_count).to eq expected_inquiry_result.family_member_count
        expect(result.family_members).to eq expected_inquiry_result.family_members
        expect(result.payment_period).to eq expected_inquiry_result.payment_period
        expect(result.branch_name).to eq expected_inquiry_result.branch_name
        expect(result.partner).to eq expected_inquiry_result.partner
        expect(result.paid_until).to eq expected_inquiry_result.paid_until

      end
    end
  end

  describe '.create_transaction' do
    let(:payment_subject) { subject.new(bpjs_kesehatan_transaction) }

    context 'when inquiry success' do
      before do
        expect_any_instance_of(Channel::Dji::BpjsKesehatan).to receive(:inquiry).and_return success_inquiry_response
        expect_any_instance_of(Channel::Dji::BpjsKesehatan).to receive(:create).and_return success_payment_response
      end

      it 'does not raise error' do
        expect { payment_subject.create_transaction }.not_to raise_error
      end

      it 'returns correct value' do
        result = payment_subject.create_transaction
        expect(result).to be_kind_of(ResponseGeneralizer::BpjsKesehatan)
        expect(result.reference_number).to eq expected_payment_result.reference_number
        expect(result.info).to eq expected_payment_result.info
        expect(result.partner_transaction_id).to eq expected_payment_result.partner_transaction_id
        expect(result.status).to eq expected_payment_result.status
      end
    end

    context 'when inquiry fails because bill already paid' do
      before do
        expect_any_instance_of(Channel::Dji::BpjsKesehatan).to receive(:inquiry).and_raise ::Exceptions::BillAlreadyPaid.new
      end

      it 'does not raise error' do
        expect { payment_subject.create_transaction }.not_to raise_error
      end

      it 'return fail transaction' do
        result = payment_subject.create_transaction
        expect(result).to be_kind_of(ResponseGeneralizer::BpjsKesehatan)
        expect(result.status).to eq 3
      end
    end

    context 'when inquiry fails because any other reason' do
      before do
        expect_any_instance_of(Channel::Dji::BpjsKesehatan).to receive(:inquiry).and_raise ::Exceptions::DefaultError.new
      end

      it 'raises error' do
        expect { payment_subject.create_transaction }.to raise_error(::Exceptions::DefaultError)
      end
    end

    context 'when inquiry success but payment fails' do
      before do
        expect_any_instance_of(Channel::Dji::BpjsKesehatan).to receive(:inquiry).and_return success_inquiry_response
        expect_any_instance_of(Channel::Dji::BpjsKesehatan).to receive(:create).and_return failed_payment_response
      end

      it 'not raises error' do
        expect { payment_subject.create_transaction }.not_to raise_error
      end

      it 'returns failure result' do
        result = payment_subject.create_transaction
        expect(result.status).to eq(expected_failed_payment_result.status)
        expect(result.partner_transaction_id).to eq(expected_failed_payment_result.partner_transaction_id)
      end
    end
  end

  describe '.confirm_transaction' do
    context 'when transaction has no partner transaction id' do
      let(:bpjs_kesehatan_transaction_without_partner_transaction_id) { create(:bpjs_kesehatan_transaction, :without_partner_transaction_id) }
      let(:confirm_subject) { subject.new(bpjs_kesehatan_transaction_without_partner_transaction_id) }

      it 'should raise error' do
        expect{ confirm_subject.confirm_transaction }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end


    context 'when partner_transaction_id is not nil' do
      let(:check_subject) { subject.new(bpjs_kesehatan_transaction_with_partner_transaction_id) }
      it 'does not raise error' do
        expect_any_instance_of(Channel::Dji::BpjsKesehatan).to receive(:get_transaction_by_id).and_return success_payment_response
        expect { check_subject.confirm_transaction }.not_to raise_error
      end
    end
  end

end
