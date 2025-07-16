module Channel
  module Ayoconnect
    class ElectricityPostpaid < Channel::Ayoconnect::Base
      include ::Channel::Ayoconnect::Helpers::ResponseNormalizer::ElectricityPostpaid

      # Constants
      PRODUCT_TYPE = :electricity_postpaid
      API_VERSION = '2.0'
      # NOTE:
      # product code may change in production env.
      PRODUCT_CODE = ENV.fetch('AYOCONNECT_ELECTRICITY_POSTPAID_PRODUCT_CODE')

      CALLBACK_URL = ENV['AYOCONNECT_CALLBACK_URL']

      # object can only be :
      # - form object
      # - transaction object
      def initialize(object)
        @object = object
        @product_type = PRODUCT_TYPE
      end

      def inquiry_to_partner
        response = inquiry(inquiry_payload)
        build_inquiry_response(response)
      end

      def create_transaction
        inquiry_response = inquiry(inquiry_payload)

        payload = {
          partnerId: get_api_key,
          accountNumber: @object.customer_number,
          productCode: PRODUCT_CODE,
          inquiryId: inquiry_response[:data][:inquiryId],
          refNumber: @object.order_id,
          amount: @object.amount,
          CallbackUrls: [
            CALLBACK_URL
          ]
        }

        response = create(payload)

        build_payment_response(response)
      end

      def confirm_transaction
        payload = {
          partnerId: get_api_key,
          refNumber: @object.order_id
        }

        response = check_status(payload)

        build_payment_response(response)
      end

      def product_type
        PRODUCT_TYPE
      end

      private

      def inquiry_payload
        {
          partnerId: get_api_key,
          AccountNumber: @object.customer_number,
          ProductCode: PRODUCT_CODE
        }
      end

      def build_inquiry_response(response)
        details = fetch_customer_info(response)
        data = response[:data]

        ResponseGeneralizer::ElectricityPostpaid.new(data, @object.partner_object).tap do |result|
          result.bills = details[:bills]
          result.customer_number = details[:customer_number]&.strip
          result.customer_name = details[:customer_name]&.strip
          result.segmentation = details[:segmentation]&.strip
          result.power = details[:power].to_i
          result.stand_meter = details[:stand_meter]
          result.outstanding_bill = details[:outstanding_bill].to_i
          result.unpaid_bill = details[:unpaid_bill].to_i
          result.penalty_fee = details[:penalty_fee]
          result.amount = details[:amount].to_i + result.admin_charge
        end
      end

      def build_payment_response(response)
        ResponseGeneralizer::ElectricityPostpaid.new(response, @object.partner_object).tap do |result|
          result.status = response[:status]
          result.reference_number = response[:data][:token]
          result.partner_transaction_id = response[:partner_transaction_id]
        end
      end
    end
  end
end
