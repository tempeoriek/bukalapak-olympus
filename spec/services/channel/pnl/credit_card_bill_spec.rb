require "rails_helper"
include PostpaidTransactionUtility

RSpec.describe Channel::Pnl::CreditCardBill, type: :model do

  let(:customer_number) { '5251586712876427' }
  let(:biller) { create(:credit_card_biller, :non_bni, :partner_pnl) }
  let(:form) {
    Form::CreditCardBill.new(customer_number, biller.id, username: 'sliu')
  }
  let(:transaction) {
    create(:cc_transaction, :paid, credit_card_biller: biller)
  }

  before {
    allow(Toggles::WhitelistBni).to receive(:active?) { false }
    allow(Toggles::WhitelistVisa).to receive(:active?) { false }
  }

  describe '#inquiry_to_partner' do
    subject { described_class.new(form).inquiry_to_partner }

    let(:http_response) {{
      message: "Akun bank valid.",
      data: {
        valid: true,
        name: "JAMIL HAZAMI ULALALA"
      },
      meta: {
        http_status: 200
      }
    }}

    let(:response) {
      ResponseGeneralizer::CreditCardBill.new do |r|
        r.customer_number = '5251-58XX-XXXX-6427'
        r.biller = biller
        r.partner = biller.partner
        r.customer_name = http_response.dig(:data, :name)
        r.card_data = customer_number
      end
    }
    it {
      allow_any_instance_of(described_class).to receive(:inquiry).and_return http_response
      expect(subject.attributes).to eq response.attributes
    }
  end

  describe '#create_transaction' do
    subject { described_class.new(transaction).create_transaction }

    let(:http_response) {{
      message: "Permintaan anda berhasil diproses",
      meta: {
        http_status: 200
      }
    }}

    let(:response) {
      ResponseGeneralizer::CreditCardBill.new do |r|
        r.status = PROCESS
        r.partner_transaction_id = transaction.order_id
      end
    }
    it {
      allow_any_instance_of(described_class).to receive(:create).and_return http_response
      expect(subject.attributes).to eq response.attributes
    }
  end

  describe '#confirm_transaction' do
    subject { described_class.new(transaction).confirm_transaction }

    context 'when success' do
      let(:http_response) {{
        data: {
          sender_party: {
            name: "BUKALAPAK.COM PT"
          },
          inquiry_status_code: "ACSP",
          customer_reference: "CC-1",
          transaction: {
            settlement_amount: 446000,
            rejected_code: "",
            status_code: "ACTC",
            reference_id: "R20201231231",
            amount: 446000,
            settlement_date: "2020-06-15 13:18:07.123",
            status_description: ""
          },
          receiving_party: {
            name: "GIORNO GIOVANNA",
            account_number: "2932d03d3ba04ae4a770240f3ba8bd34bce93ebd1d2549d69ad483df13e513f8",
            bank_name: "Bank Mega",
            bank_code: "426"
          }
        },
        meta: {
          http_status: 200
        }
      }}

      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = SUCCESS
          r.reference_number = http_response.dig(:data, :transaction, :reference_id)
        end
      }
      it {
        allow_any_instance_of(described_class).to receive(:confirm).and_return http_response
        expect(subject.attributes).to eq response.attributes
      }
    end

    context 'when failed' do
      let(:http_response) {{
        data: {
          sender_party: {
            name: ""
          },
          customer_reference: "CC-1",
          receiving_party: {
            name: "",
            account_number: "2932d03d3ba04ae4a770240f3ba8bd34bce93ebd1d2549d69ad483df13e513f8",
            bank_code: "",
            bank_name: ""
          },
          inquiry_status_code: "ACSP",
          transaction: {
            reference_id: "R20201231231",
            status_description: "Do Not Honor",
            status_code: "RJCT",
            rejected_code: "04",
            settlement_date: "",
            settlement_amount: 0,
            amount: 0
          }
        },
        meta: {
          http_status: 200
        }
      }}

      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = PROCESS
          r.reference_number = http_response.dig(:data, :transaction, :reference_id)
        end
      }
      it {
        allow_any_instance_of(described_class).to receive(:confirm).and_return http_response
        expect(subject.attributes).to eq response.attributes
      }
    end

    context 'when balance insufficient' do
      let(:http_response) {{
        data: {
          sender_party: {
            name: ""
          },
          customer_reference: "CC-1",
          receiving_party: {
            name: "",
            account_number: "2932d03d3ba04ae4a770240f3ba8bd34bce93ebd1d2549d69ad483df13e513f8",
            bank_code: "",
            bank_name: ""
          },
          inquiry_status_code: "RJCT",
          transaction: {
            reference_id: "R20201231231",
            status_description: "Insufficient Funds",
            status_code: "RJCT",
            rejected_code: "51",
            settlement_date: "",
            settlement_amount: 0,
            amount: 0
          }
        },
        meta: {
          http_status: 200
        }
      }}

      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = FAILED
          r.reference_number = http_response.dig(:data, :transaction, :reference_id)
        end
      }
      it {
        allow_any_instance_of(described_class).to receive(:confirm).and_return http_response
        expect(subject.attributes).to eq response.attributes
      }
    end
  end
end
