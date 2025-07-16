require "rails_helper"

RSpec.describe Channel::Visa::CyberSource::SecureAcceptanceCheckout, type: :model do

  let(:bill_to_forename) { 'jeremy' }
  let(:bill_to_surname)  { 'tan' }
  let(:bill_to_email)    { 'kamado.tan@jiro.com' }
  let(:card_number)      { '4111111111111111' }
  let(:card_expiry_date) { '05-2021' }
  let(:amount)           { '500000' }

  let(:biller_visa) { create(:credit_card_biller, :visa, :partner_visa) }

  let(:token_receipt_accept) {
    File.read('spec/fixtures/visa/cyber_source/token_receipt_accept.html')
  }
  let(:token_receipt_decline) {
    File.read('spec/fixtures/visa/cyber_source/token_receipt_decline.html')
  }
  let(:token_receipt_error) {
    File.read('spec/fixtures/visa/cyber_source/token_receipt_error.html')
  }

  subject {
    described_class.new(
      bill_to_forename: bill_to_forename,
      bill_to_surname: bill_to_surname,
      bill_to_email: bill_to_email,
      card_number: card_number,
      card_expiry_date: card_expiry_date,
      amount: '0'
    )
  }

  describe '#url' do
    it { expect(subject.url).to eq Channel::Config::VISA_CYBS_TOKEN_URL }
  end

  describe '#payload' do
    it {
      expect(subject.payload).to include(
        'access_key',
        'profile_id',
        'transaction_uuid',
        'signed_field_names',
        'unsigned_field_names',
        'locale',
        'transaction_type',
        'reference_number',
        'amount',
        'currency',
        'payment_method',
        'bill_to_forename',
        'bill_to_surname',
        'bill_to_email',
        'bill_to_phone',
        'bill_to_address_line1',
        'bill_to_address_city',
        'bill_to_address_state',
        'bill_to_address_country',
        'bill_to_address_postal_code',
        'signed_date_time',
        'signature',
        'card_type',
        'card_number',
        'card_expiry_date'
      )
    }
    it 'bill_to_forename not to be empty' do
      expect(subject.payload['bill_to_forename']).not_to be_empty
    end
    it 'bill_to_surname not to be empty' do
      expect(subject.payload['bill_to_surname']).not_to be_empty
    end
    it 'bill_to_email not to be empty' do
      expect(subject.payload['bill_to_email']).not_to be_empty
    end
    it 'card_number not to be empty' do
      expect(subject.payload['card_number']).not_to be_empty
    end
    it 'card_expiry_date not to be empty' do
      expect(subject.payload['card_expiry_date']).not_to be_empty
    end
  end

  describe '#tokenize_card' do
    context 'success' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:post)
          .with(kind_of(String), nil, kind_of(Hash), kind_of(Hash), kind_of(Hash))
          .and_return(token_receipt_accept)
      }
      it ':decision is ACCEPT' do
        token_result = subject.tokenize_card
        expect(token_result[:decision]).to eq 'ACCEPT'
      end
      it 'has :payment_token key' do
        token_result = subject.tokenize_card
        expect(token_result).to include(:payment_token)
      end
    end

    context 'decline' do
      let(:bill_to_forename) { '-' }
      before {
        allow(Channel::Connection::Http)
          .to receive(:post)
          .with(kind_of(String), nil, kind_of(Hash), kind_of(Hash), kind_of(Hash))
          .and_return(token_receipt_decline)
      }
      it ':decision is DECLINE' do
        token_result = subject.tokenize_card
        expect(token_result[:decision]).to eq 'DECLINE'
      end
      it "doesn't have :payment_token key" do
        token_result = subject.tokenize_card
        expect(token_result).not_to include(:payment_token)
      end
    end

    context 'error' do
      let(:bill_to_forename) { '' }
      before {
        allow(Channel::Connection::Http)
          .to receive(:post)
          .with(kind_of(String), nil, kind_of(Hash), kind_of(Hash), kind_of(Hash))
          .and_return(token_receipt_error)
      }
      it ':decision is ERROR' do
        token_result = subject.tokenize_card
        expect(token_result[:decision]).to eq 'ERROR'
      end
      it "doesn't have :payment_token key" do
        token_result = subject.tokenize_card
        expect(token_result).not_to include(:payment_token)
      end
    end
  end
end
