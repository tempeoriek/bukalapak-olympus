require "rails_helper"
include PostpaidTransactionUtility

RSpec.describe Channel::Visa::CreditCardBill, type: :model do

  let(:customer_number) { '4111111111111111' }
  let(:biller) { create(:credit_card_biller, :visa, :partner_visa) }
  let(:form) {
    Form::CreditCardBill.new(customer_number, biller.id, username: 'sliu')
  }
  let(:rc_prefix) { Channel::Visa::Base::RC_PREFIX }
  let(:trx) {
    create(:cc_transaction, :processed_visa, credit_card_biller_id: biller.id, credit_card_bill_partner_id: biller.partner.id)
  }
  let(:trx_no_token) {
    create(:cc_transaction, :processed_visa, credit_card_biller_id: biller.id, credit_card_bill_partner_id: biller.partner.id, token: nil)
  }
  let(:trx_no_ref_num) {
    create(:cc_transaction, :processed_visa, credit_card_biller_id: biller.id, credit_card_bill_partner_id: biller.partner.id, reference_number: nil)
  }
  let(:token_receipt_accept) {
    File.read('spec/fixtures/visa/cyber_source/token_receipt_accept.html')
  }
  let(:token_receipt_decline) {
    File.read('spec/fixtures/visa/cyber_source/token_receipt_decline.html')
  }
  let(:token_receipt_error) {
    File.read('spec/fixtures/visa/cyber_source/token_receipt_error.html')
  }
  let(:token_receipt_unknown) {
    File.read('spec/fixtures/visa/cyber_source/token_receipt_unknown.html')
  }
  let(:payouts_accepted) {
    File.read('spec/fixtures/visa/cyber_source/payouts_accepted.json')
  }
  let(:payouts_declined) {
    File.read('spec/fixtures/visa/cyber_source/payouts_declined.json')
  }
  let(:search_transaction_found) {
    File.read('spec/fixtures/visa/cyber_source/search_transaction_found.json')
  }
  let(:search_transaction_not_found) {
    File.read('spec/fixtures/visa/cyber_source/search_transaction_not_found.json')
  }

  before {
    allow(Toggles::WhitelistBni).to receive(:active?).and_return false
    allow(Toggles::WhitelistVisa).to receive(:active?).and_return true
    allow(Toggles::OlympusSievexSend).to receive(:active?).and_return false
  }

  describe '#secure_acceptance_token' do
    subject {
      described_class.new(form).secure_acceptance_token
    }
    context 'when success' do
      before {
        allow(Channel::Connection::Http).to receive(:post).and_return(token_receipt_accept)
      }
      it 'returns masked card number and token' do
        expect(subject.keys).to include(:req_card_number, :payment_token)
      end
    end

    context 'when failed' do
      it {
        allow(Channel::Connection::Http).to receive(:post).and_return(token_receipt_decline)
        expect{ subject }.to raise_error(Exceptions::Visa::InvalidCreditCardNumber)
      }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_return(token_receipt_error)
        expect{ subject }.to raise_error(Exceptions::Visa::InvalidCreditCardNumber)
      }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_return(token_receipt_unknown)
        expect{ subject }.to raise_error(Exceptions::Visa::GeneralError)
      }
    end

    context 'when error' do
      it {
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception.new)
        expect{ subject }.to raise_error(RestClient::Exception)
      }
    end
  end

  describe '#inquiry_to_partner' do
    subject {
      described_class.new(form).inquiry_to_partner
    }
    let(:response) {
      ResponseGeneralizer::CreditCardBill.new do |r|
        r.customer_number = 'XXXX-XXXX-XXXX-1111'
        r.biller = form.biller
        r.partner = form.biller.partner
        r.customer_name = ''
        r.response_code = "#{rc_prefix}100"
        r.token = '7010000000112271111'
        r.card_data = nil
      end
    }
    before {
      allow(Channel::Connection::Http).to receive(:post).and_return(token_receipt_accept)
    }
    it { expect(subject.attributes).to match response.attributes }
  end

  describe '#create_transaction' do
    subject {
      described_class.new(trx).create_transaction
    }
    let(:ref_num) { '33557799' }
    before {
      allow_any_instance_of(Channel::Visa::CyberSource::Payouts).to receive(:reference_code).and_return ref_num
    }
    context 'when success' do
      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = SUCCESS
          r.reference_number = ref_num
          r.response_code = "#{rc_prefix}00"
          r.partner_transaction_id = '5908718291286196503005'
        end
      }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_return(payouts_accepted)
        expect(subject.attributes).to match response.attributes
      }
    end

    context 'when failed' do
      context 'when token is gone' do
        subject {
          described_class.new(trx_no_token).create_transaction
        }
        let(:response) {
          ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = FAILED
            r.reference_number = nil
            r.response_code = "#{rc_prefix}NO_TOKEN"
          end
        }
        it {
          allow(Channel::Connection::Http).to receive(:post).and_return(payouts_declined)
          expect(subject.attributes).to match response.attributes
        }
      end

      context 'when payout request failed' do
        let(:response) {
          ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = PENDING
            r.reference_number = ref_num
            r.response_code = "#{rc_prefix}INVALID_REQUEST"
          end
        }
        it {
          allow(Channel::Connection::Http).to receive(:post).and_return(payouts_declined)
          expect(subject.attributes).to match response.attributes
        }
      end
    end

    context 'when error' do
      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = PROCESS
          r.reference_number = ref_num
          r.response_code = 'timeout'
        end
      }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::Timeout.new('Timed out reading data from server'))
        expect(subject.attributes).to match response.attributes
      }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception.new)
        expect{ subject }.to raise_error(RestClient::Exception)
      }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_raise(StandardError)
        expect{ subject }.to raise_error(StandardError)
      }
    end
  end

  describe '#delete_token' do
    subject {
      described_class.new(trx).delete_token
    }
    context 'when success' do
      it {
        allow_any_instance_of(Channel::Visa::CyberSource::DeleteToken).to receive(:send_request).and_return true
        is_expected.to eq true
      }
    end

    context 'when failed' do
      context 'when token is gone' do
        subject {
          described_class.new(trx_no_token).delete_token
        }
        it { is_expected.to eq true }
        it 'does not call send_request request' do
          expect_any_instance_of(Channel::Visa::CyberSource::DeleteToken).not_to receive(:send_request)
          subject
        end
      end

      context 'when delete token request failed' do
        it {
          allow_any_instance_of(Channel::Visa::CyberSource::DeleteToken).to receive(:send_request).and_return false
          is_expected.to eq false
        }
      end
    end

    context 'when error' do
      it {
        allow_any_instance_of(Channel::Visa::CyberSource::DeleteToken).to receive(:send_request).and_raise(RestClient::Exception.new)
        is_expected.to eq false
      }
    end
  end

  describe '#confirm_transaction' do
    subject {
      described_class.new(trx).confirm_transaction
    }
    context 'when success' do
      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = SUCCESS
          r.response_code = "#{rc_prefix}100"
          r.partner_transaction_id = '5925894301016594603001'
        end
      }
      it {
        allow_any_instance_of(CreditCardBillTransaction).to receive(:reference_number).and_return('20200620005708979735')
        allow(Channel::Connection::Http).to receive(:post).and_return(search_transaction_found)
        expect(subject.attributes).to match response.attributes
      }
    end

    context 'when failed' do
      context 'when no reference_number' do
        subject {
          described_class.new(trx_no_ref_num).confirm_transaction
        }
        let(:response) {
          ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = PENDING
            r.response_code = "#{rc_prefix}NO_REF_CODE"
          end
        }
        it {
          expect(subject.attributes).to match response.attributes
        }
      end

      context 'when search_transaction not found' do
        let(:response) {
          ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = PENDING
            r.response_code = 'TRX_NOT_FOUND'
            r.partner_transaction_id = nil
          end
        }
        it {
          allow(Channel::Connection::Http).to receive(:post).and_return(search_transaction_not_found)
          expect(subject.attributes).to match response.attributes
        }
      end
    end

    context 'when error' do
      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = PENDING
          r.response_code = 'timeout'
        end
      }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::Timeout.new('Timed out reading data from server'))
        expect(subject.attributes).to match response.attributes
      }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception.new)
        expect{ subject }.to raise_error(RestClient::Exception)
      }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_raise(StandardError)
        expect{ subject }.to raise_error(StandardError)
      }
    end
  end

end
