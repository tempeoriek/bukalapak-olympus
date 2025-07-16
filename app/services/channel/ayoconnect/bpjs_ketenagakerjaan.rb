module Channel
  module Ayoconnect
    class BpjsKetenagakerjaan < Channel::Ayoconnect::Base
      include ::Channel::Ayoconnect::Helpers::ResponseNormalizer::BpjsKetenagakerjaan

      # Constants
      PRODUCT_TYPE = :bpjs_ketenagakerjaan
      API_VERSION  = '2.0'.freeze
      # NOTE:
      # product code may change in production env.
      BPJS_KETENAGAKERJAAN_PRODUCT_CODES = {
        bpu: ENV.fetch('AYOCONNECT_BPJS_KETENAGAKERJAAN_BPU_PRODUCT_CODE'),
        pu: ENV.fetch('AYOCONNECT_BPJS_KETENAGAKERJAAN_PU_PRODUCT_CODE')
      }.freeze

      CALLBACK_URL     = ENV['AYOCONNECT_CALLBACK_URL']

      # object can only be :
      # - form object
      # - transaction object
      def initialize(object)
        @object = object
        @product_type = PRODUCT_TYPE
      end

      def inquiry_to_partner
        if Rails.env.development? || ::Toggles::BpjsKetenagakerjaanAyoconnectMock.active?
          response = Mocks::BpjsKetenagakerjaan.inquiry(inquiry_payload)
          raise_inquiry_error!(response['responseCode']) if inquiry_request_fail?(response['responseCode'])
        else
          response = inquiry(inquiry_payload)
        end
        build_inquiry_response(response)
      end

      def create_transaction
        if Rails.env.development? || ::Toggles::BpjsKetenagakerjaanAyoconnectMock.active?
          inquiry_response = Mocks::BpjsKetenagakerjaan.inquiry(inquiry_payload)
          if inquiry_request_fail?(inquiry_response['responseCode'])
            raise_inquiry_error!(inquiry_response['responseCode'])
          end
        else
          inquiry_response = inquiry(inquiry_payload)
        end

        payload = {
          partnerId: get_api_key,
          accountNumber: @object.customer_number,
          productCode: BPJS_KETENAGAKERJAAN_PRODUCT_CODES[@object.bpjs_tk_type.to_sym],
          inquiryId: inquiry_response[:data][:inquiryId],
          refNumber: @object.order_id,
          amount: @object.amount,
          CallbackUrls: [
            CALLBACK_URL
          ]
        }

        response = if Rails.env.development? || ::Toggles::BpjsKetenagakerjaanAyoconnectMock.active?
                     Mocks::BpjsKetenagakerjaan.create(payload)
                   else
                     create(payload)
                   end

        build_payment_response(response)
      end

      def confirm_transaction
        payload = {
          partnerId: get_api_key,
          refNumber: @object.order_id
        }

        response = if Rails.env.development? || ::Toggles::BpjsKetenagakerjaanAyoconnectMock.active?
                     Mocks::BpjsKetenagakerjaan.check_status(payload)
                   else
                     check_status(payload)
                   end

        build_payment_response(response)
      end

      def product_type
        PRODUCT_TYPE
      end

      private

      def inquiry_payload
        {
          partnerId: get_api_key,
          accountNumber: @object.customer_number,
          productCode: BPJS_KETENAGAKERJAAN_PRODUCT_CODES[@object.bpjs_tk_type.to_sym],
          month: @object.payment_period.to_i
        }
      end

      def build_inquiry_response(response)
        details = fetch_customer_info(response, @object.bpjs_tk_type)

        ResponseGeneralizer::BpjsKetenagakerjaan.new.tap do |result|
          result.bills = details[:bills]
          result.partner = AYOCONNECT
          result.customer_number = details[:customer_number]&.strip
          result.customer_name = details[:customer_name]&.strip
          result.bpjs_tk_type = @object.bpjs_tk_type
          result.bukalapak_admin_charge = @object.partner_object.bukalapak_admin_charge
          result.partner_admin_charge = @object.partner_object.partner_admin_charge
          result.amount = details[:amount].to_i + result.admin_charge
          result.payment_period = @object.payment_period
          result.start_bill_period = details[:start_bill_period]
          result.end_bill_period = details[:end_bill_period]
          result.npp = details[:npp]
          result.division = details[:division]
          result.bill_code = details[:bill_code]
          result.reference_number = details[:reference_number]
          result.branch_name = details[:branch_name]
          result.unpaid_bills = details[:unpaid_bills]
          result.unpaid_bills_text = details[:unpaid_bills_text]
        end
      end

      def build_payment_response(response)
        ResponseGeneralizer::BpjsKetenagakerjaan.new.tap do |result|
          result.status = response[:status]
          result.reference_number = response[:data][:token]
          result.partner_transaction_id = response[:partner_transaction_id]
        end
      end
    end
  end
end
