# frozen_string_literal: true

module Channel
  module Tektaya
    class ElectricityPostpaid < Channel::Tektaya::Base
      include Channel::Tektaya::Helpers::ResponseNormalizer::ElectricityPostpaidInquiry
      include Channel::Tektaya::Helpers::ResponseNormalizer::ElectricityPostpaidPayment

      # Constants
      PRODUCT_TYPE             = :electricity_postpaid
      PRODUCT_CODE             = '200'
      ELECTRICITY_POSTPAID_URL = "#{TEKTAYA_HOST}#{TEKTAYA_POSTPAID_URL}"

      # Maximum number of randoms
      RANDOM_MAX_NUMBER        = 999_999

      # object can only be :
      # - form object
      # - transaction object
      def initialize(object)
        super(object)
      end

      def inquiry_to_partner
        validate_object!

        payload  = build_inquiry_payload
        response = request(ELECTRICITY_POSTPAID_URL, payload, action: 'inquiry')

        rc = response.dig('tty', 'respcode')
        raise_inquiry_error!(rc) unless get_status_from_response_code(rc) == :success

        build_inquiry_response(response)
      end

      def create_transaction
        validate_object!

        # According to Tektaya, inquiry is required before payment
        begin
          inquiry_payload  = build_inquiry_payload(before_checkout: false)
          inquiry_response = request(ELECTRICITY_POSTPAID_URL, inquiry_payload, action: 'inquiry')
          handle_inquiry_response_from_payment!(inquiry_response)
        rescue StandardError => e
          @object.update!(state: 'paid')
          raise e
        end

        payment_payload  = build_payment_payload
        payment_response = request(ELECTRICITY_POSTPAID_URL, payment_payload, action: 'payment', with_retry: false)

        build_payment_response(payment_response)
      end

      def product_type
        PRODUCT_TYPE
      end

      private

      def validate_object!
        raise ::Exceptions::GeneralError.new unless @object.is_a?(::Form::ElectricityPostpaid) || @object.is_a?(::PostpaidTransaction)
      end

      def build_inquiry_payload(before_checkout: true)
        buyer_type_config = retrieve_buyer_type_config(buyer_type)

        # Inquiry needs an ID to proceed. After checkout, transaction is already created.
        transaction_id    = before_checkout ? generate_random_id : @object.order_id.tr('-', '')

        {
          mti: ELECTRICITY_POSTPAID_INQUIRY_MTI,
          kdproduk: PRODUCT_CODE,
          userid: buyer_type_config[:user_id],
          password: buyer_type_config[:password],
          bit62: buyer_type_config[:bit62],
          sessionkey: retrieve_session_key,
          idpel: @object.customer_number,
          trxid: transaction_id
        }
      end

      def build_inquiry_response(response)
        data = fetch_inquiry_info(response)

        ResponseGeneralizer::ElectricityPostpaid.new(data, @object.partner_object).tap do |result|
          result.bills = data[:bills]
          result.customer_number = data[:customer_number]&.strip
          result.customer_name = data[:customer_name]&.strip
          result.segmentation = data[:segmentation]&.strip
          result.power = data[:power].to_i
          result.stand_meter = data[:stand_meter]
          result.outstanding_bill = data[:outstanding_bill].to_i
          result.unpaid_bill = data[:unpaid_bill].to_i
          result.penalty_fee = data[:penalty_fee]
          result.amount = data[:amount].to_i + result.penalty_fee + result.admin_charge
        end
      end

      def build_payment_payload
        buyer_type_config = retrieve_buyer_type_config(buyer_type)

        {
          mti: ELECTRICITY_POSTPAID_PAYMENT_MTI,
          kdproduk: PRODUCT_CODE,
          userid: buyer_type_config[:user_id],
          password: buyer_type_config[:password],
          bit62: buyer_type_config[:bit62],
          sessionkey: retrieve_session_key,
          idpel: @object.customer_number,
          trxid: @object.order_id.tr('-', '')
        }
      end

      def build_payment_response(response)
        data   = fetch_payment_info(response)
        status = get_status_from_response_code(response.dig('tty', 'respcode')) || :pending

        ResponseGeneralizer::ElectricityPostpaid.new(data, @object.partner_object).tap do |result|
          result.status = PARTNER_STATUS[TEKTAYA][status.to_s]
          result.reference_number = data[:reference_number]
          result.partner_transaction_id = data[:partner_transaction_id]
          result.info_text = data[:info_text]
        end
      end

      def handle_inquiry_response_from_payment!(inquiry_response)
        response_code  = inquiry_response.dig('tty', 'respcode')
        raise_inquiry_error!(response_code) unless get_status_from_response_code(response_code) == :success

        inquiry_result = build_inquiry_response(inquiry_response)

        raise Exceptions::AmountMismatch.new(bl_amount: @object.amount, partner_amount: inquiry_result.amount) if @object.amount != inquiry_result.amount
      end

      # Inquiry needs a trxid. And before we checkout, the transaction is not yet created.
      # So we need to generate random ID to enable the inquiry before checkout.
      # It is random-ed for to make the tracing easier.
      def generate_random_id
        "INQ#{Random.rand(RANDOM_MAX_NUMBER)}"
      end

      def raise_inquiry_error!(rc)
        case rc
        when '14', '15'
          raise ::Exceptions::UnregisteredNumber.new
        when '17'
          raise ::Exceptions::BillExceedLimit.new
        when '54', '55', '88', '89'
          raise ::Exceptions::BillAlreadyPaid.new
        else
          raise ::Exceptions::DefaultError.new
        end
      end
    end
  end
end
