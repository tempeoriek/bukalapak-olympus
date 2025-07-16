require 'rails_helper'

RSpec.describe CachePartnerResponseUtility, type: :model do
  include ::Postpaid::Constant

  let(:dummy_class) {
    Class.new do
      include CachePartnerResponseUtility
    end
  }
  let(:product_type) { ELECTRICITY_PRODUCT }
  let(:action) { "inquiry" }
  let(:partner) { SEPULSA }
  let(:reference_id) { '0812345567678' }
  let(:response_code) { MiddlemanResponseMapperUtility::SepulsaRC::BILL_ALREADY_PAID_OR_NOT_AVAILABLE }

  describe '#cache_partner_response' do
    subject { dummy_class.new.cache_partner_response(product_type, action, partner, reference_id, response_code) }

    context 'when response_code nil' do
      let(:response_code) { "" }

      before {
        expect(RedisOlympus).not_to receive(:set)
      }

      it { is_expected.to be_nil }
    end

    context 'when reference_id nil' do
      let(:reference_id) { "" }

      before {
        expect(RedisOlympus).not_to receive(:set)
      }

      it { is_expected.to be_nil }
    end

    context 'when product_type is not allowed' do
      let(:product_type) { BPJS_KESEHATAN_PRODUCT }

      before {
        expect(RedisOlympus).not_to receive(:set)
      }

      it { is_expected.to be_nil }
    end

    context 'when Redis Timeout' do
      before {
        expect(RedisOlympus).to receive(:set).and_raise(RestClient::Exceptions::OpenTimeout)
      }

      it { is_expected.to be_nil }
    end

    allowed_products = [ELECTRICITY_PRODUCT, CREDIT_CARD_BILL_PRODUCT]
    allowed_products.each do |product_type|
      context "when succesfully caching partner response with #{product_type}" do

        subject { dummy_class.new.cache_partner_response(product_type, action, partner, reference_id, response_code) }

        before {
          expect(RedisOlympus).to receive(:set).with(kind_of(String), response_code, hash_including(:ex))
        }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#retrieve_partner_response' do
    subject { dummy_class.new.retrieve_partner_response(product_type, action, partner, reference_id) }

    context 'when reference_id nil' do
      let(:reference_id) { "" }

      before {
        expect(RedisOlympus).not_to receive(:set)
      }

      it { is_expected.to be_nil }
    end

    context 'when product_type is not allowed' do
      let(:product_type) { PDAM_PRODUCT }

      before {
        expect(RedisOlympus).not_to receive(:set)
      }

      it { is_expected.to be_nil }
    end

    context 'when Redis Timeout' do
      before {
        expect(RedisOlympus).to receive(:get).and_raise(RestClient::Exceptions::OpenTimeout)
      }

      it { is_expected.to be_nil }
    end

    allowed_products = [ELECTRICITY_PRODUCT, CREDIT_CARD_BILL_PRODUCT]
    allowed_products.each do |product_type|
      context "when succesfully caching partner response #{product_type}" do
        subject { dummy_class.new.retrieve_partner_response(product_type, action, partner, reference_id) }

        before {
          expect(RedisOlympus).to receive(:get).with(kind_of(String)).and_return(response_code)
        }

        it { is_expected.to eq(response_code) }
      end
    end
  end
end
