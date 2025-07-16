require 'rails_helper'

RSpec.describe MiddlemanResponseMapperUtility, type: :model do
  include ::Postpaid::Constant

  let(:dummy_class) {
    Class.new do
      include MiddlemanResponseMapperUtility
    end
  }
  let(:product_type) { ELECTRICITY_PRODUCT }
  let(:partner) { SEPULSA }
  let(:partner_response_code) { described_class::SepulsaRC::BILL_ALREADY_PAID_OR_NOT_AVAILABLE }
  let(:expected_response) { described_class::MiddlemanRC::BILL_NOT_FOUND_OR_ALREADY_PAID }

  describe '#retrieve_middleman_response_code' do
    subject { dummy_class.new.retrieve_middleman_response_code(product_type, partner, partner_response_code) }

    context 'when product_type unknown' do
      let(:product_type) { BPJS_KESEHATAN_PRODUCT }

      it { is_expected.to eq(described_class::MiddlemanRC::GENERAL) }
    end

    context 'when partner unknown' do
      let(:partner) { DJI }

      it { is_expected.to eq(described_class::MiddlemanRC::GENERAL) }
    end

    context 'when partner_response_code unknown' do
      let(:partner_response_code) { 'unknown' }

      it { is_expected.to eq(described_class::MiddlemanRC::GENERAL) }
    end

    context 'when all attribute is match' do
      it { is_expected.to eq(expected_response) }
    end

    context 'with partner Thor' do
      let(:partner)               { THOR }
      let(:partner_response_code) { described_class::ThorRC::BILLS_ALREADY_PAID }
      let(:expected_response)     { described_class::MiddlemanRC::BILL_NOT_FOUND_OR_ALREADY_PAID }

      context 'with product_type Electricity Postpaid' do
        it { is_expected.to eq(expected_response) }
      end

      context 'with product_type PDAM' do
        let(:product_type) { PDAM_PRODUCT }

        it { is_expected.to eq(expected_response) }
      end

      context 'with other response code' do
        let(:partner_response_code) { described_class::ThorRC::REFERENCE_NUMBER_INVALID }
        let(:expected_response)     { described_class::MiddlemanRC::INVALID_CUSTOMER_NUMER }

        it { is_expected.to eq(expected_response) }
      end

      # currently Thor supported for electricity postpaid and PDAM
      context 'with product_type unknown' do
        let(:product_type) { CREDIT_CARD_BILL_PRODUCT}

        it { is_expected.to eq(described_class::MiddlemanRC::GENERAL) }
      end
    end
  end

  describe '#retrieve_middleman_failed_reason' do
    subject { dummy_class.new.retrieve_middleman_failed_reason(partner, partner_response_code) }

    context 'when partner_response_code blank' do
      let(:partner_response_code) { "" }

      it { is_expected.to be_nil }
    end

    context 'when all attribute is match' do
      let(:expected_response) { "#{partner}|#{partner_response_code}" }
      it { is_expected.to eq(expected_response) }
    end

    context 'with partner thor' do
      let(:partner)               { THOR }
      let(:partner_response_code) { described_class::ThorRC::BILLS_ALREADY_PAID }
      let(:expected_response)     { described_class::MiddlemanRC::BILL_NOT_FOUND_OR_ALREADY_PAID }

      context 'when partner_response_code blank' do
        let(:partner_response_code) { "" }
  
        it { is_expected.to be_nil }
      end
  
      context 'when all attribute is match' do
        let(:expected_response) { "#{partner}|#{partner_response_code}" }
        it { is_expected.to eq(expected_response) }
      end
    end
  end
end
