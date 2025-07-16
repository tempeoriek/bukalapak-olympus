module Channel
  module Thor
    class ElectricityPostpaid < ::Channel::Thor::Base
      PRODUCT_TYPE = 'electricity_postpaid'.freeze
      INQUIRY_URL  = '/v1/transactions/postpaid-electricities/customers'.freeze
      CONFIRM_URL  = '/v1/transactions/postpaid-electricities/order-id/'.freeze
      CREATE_TRANSACTION_URL = '/v1/transactions/postpaid-electricities'.freeze

      THOR_RESPONSE_INQUIRY_KEY     = 'postpaid_electricity_customer'.freeze
      THOR_RESPONSE_TRANSACTION_KEY = 'postpaid_electricity_transaction'.freeze

      def initialize(object)
        @object = object
        @product_type = PRODUCT_TYPE
      end

      def inquiry_to_partner
        payload = {
          customer_number: @object.customer_number,
          product_code: @object.partner_object.code
        }

        response = inquiry(payload)

        build_inquiry_response(response)
      end

      def create_transaction
        payload = {
          customer_number: @object.customer_number,
          product_code: @object.partner_object.code,
          order_id: @object.id.to_s
        }
       
        response = create(payload)

        build_transaction_response(response)
      end

      def confirm_transaction
        response = get_transaction_by_id(@object.id)

        build_transaction_response(response)
      end

      def product_type
        PRODUCT_TYPE
      end

      private

      def build_inquiry_response(response)
        bills_from_response = response[:bills].nil? ? [] : response[:bills]

        bills = inquiry_bills(bills_from_response)
        penalty_fee = total_penalty_fee(bills_from_response)

        ResponseGeneralizer::ElectricityPostpaid.new(response, @object.partner_object).tap do |result|
          result.bills = bills
          result.customer_number = response[:customer_number]&.strip
          result.customer_name = response[:customer_name]&.strip
          result.segmentation = response[:segmentation]&.strip
          result.power = response[:power].to_i
          result.stand_meter = response[:stand_meter]
          result.outstanding_bill = response[:outstanding_bill].to_i
          result.unpaid_bill = response[:unpaid_bill].to_i
          result.penalty_fee = penalty_fee
          result.amount = calculate_total_amount(bills) + result.admin_charge + penalty_fee
          result.remaining_billing_sheet = response[:remaining_billing_sheet].to_i
        end
      end

      def build_transaction_response(response)
        bills_from_response = response[:bills].nil? ? [] : response[:bills]

        bills = inquiry_bills(bills_from_response)

        ResponseGeneralizer::ElectricityPostpaid.new(response, @object.partner_object).tap do |result|
          result.status = response[:status]
          result.reference_number = response[:reference_number]
          result.bills = bills
          result.info_text = response[:info_text]
          result.message = response[:message]
        end
      end

      def inquiry_bills(bills)
        bills&.map do |bill|
          {
            bill_period: bill[:period],
            due_date: nil,
            penalty_fee: bill[:penalty_fee]&.to_i || 0,
            amount: bill[:amount]&.to_i || 0
          }
        end
      end

      def total_penalty_fee(bills)
        bills.map { |bill| bill[:penalty_fee].to_i }.inject(0, :+)
      end

      def calculate_total_amount(bills)
        bills.map { |bill| bill[:amount].to_i }.inject(0, :+)
      end
    end
  end
end
