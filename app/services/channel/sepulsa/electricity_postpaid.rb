module Channel
  module Sepulsa
    class ElectricityPostpaid < Channel::Sepulsa::Base
      PRODUCT_ID = ENV['POSTPAID_PRODUCT'].to_i.freeze

      # object can only be :
      # - form object
      # - transaction object
      def initialize(object)
        @object = object
        @tclose = Time.zone.parse('22:45')
        @topen  = Time.zone.parse('01:00')
      end

      def inquiry_to_partner
        raise ::Exceptions::ClosedTimeError.new(@tclose, @topen) if is_closed_time?

        payload = {
          product_id: PRODUCT_ID,
          customer_number: @object.customer_number
        }
        response = inquiry(payload)
        build_response(response)
      end

      def create_transaction
        payload = {
          product_id: PRODUCT_ID,
          customer_number: @object.customer_number,
          amount: @object.amount - @object.admin_charge,
          order_id: @object.order_id
        }
        response = create(payload, @object.remote_transaction_id)
        result = ResponseGeneralizer::ElectricityPostpaid.new(response, @object.partner_object)
        result.segmentation = response[:subscriber_segmentation]
        result.power = response[:power]
        result.stand_meter = response[:stand_meter_summary]
        result.status = response[:status]
        result.reference_number = response[:reference_number]
        result
      end

      def confirm_transaction
        if @object.partner_transaction_id.nil?
          confirm_with_order_id
        else
          confirm_with_partner_transaction_id
        end
      end

      def confirm_with_partner_transaction_id
        response = get_transaction_by_id(@object.partner_transaction_id, ELECTRICITY_PRODUCT)
        result = ResponseGeneralizer::ElectricityPostpaid.new(response, @object.partner_object)
        result.segmentation = response[:subscriber_segmentation]
        result.power = response[:power]
        result.stand_meter = response[:stand_meter_summary]
        result.info_text = response[:info_text]
        result.reference_number = response[:switcher_refno]
        result.status = response[:status]
        result
      end

      def confirm_with_order_id
        response = get_transaction_by_order_id(@object.order_id, ELECTRICITY_PRODUCT)
        result = ResponseGeneralizer::ElectricityPostpaid.new(response, @object.partner_object)
        result.segmentation = response[:subscriber_segmentation]
        result.power = response[:power]
        result.stand_meter = response[:stand_meter_summary]
        result.info_text = response[:info_text]
        result.partner_transaction_id = response[:partner_transaction_id]
        result.reference_number = response[:switcher_refno]
        result.status = response[:status]
        result
      end

      def product_type
        ELECTRICITY_PRODUCT
      end

      private

      def build_response(response)
        result = ResponseGeneralizer::ElectricityPostpaid.new(response, @object.partner_object)
        result.bills = build_bills(response)
        result.customer_number = response[:subscriber_id]&.strip
        result.customer_name = response[:subscriber_name]&.strip
        result.segmentation = response[:subscriber_segmentation]&.strip
        result.power = response[:power].to_i
        result.stand_meter = response[:stand_meter_summary]
        result.outstanding_bill = response[:bill_status].to_i
        result.unpaid_bill = response[:outstanding_bill].to_i
        result.penalty_fee = total_penalty_fee(result.bills)
        result.amount = calculate_total_amount(result.bills) + result.admin_charge + result.penalty_fee
        result.reference_number = response[:switcher_refno]
        result
      end

      def build_bills(response)
        response[:bills]&.map do |bill|
          {
            bill_period: ::Converter::StringToDate.convert(bill[:bill_period], string_format: YYYYMM),
            due_date: ::Converter::StringToDate.convert(bill[:due_date]),
            penalty_fee: bill[:penalty_fee].to_i,
            amount: bill[:total_electricity_bill].to_i,
            previous_meter: bill[:previous_meter_reading1],
            current_meter: bill[:current_meter_reading1]
          }
        end
      end

      def calculate_total_amount(bills)
        bills&.map { |bill| bill[:amount] }&.inject(0, :+).to_i
      end

      def total_penalty_fee(bills)
        bills&.map { |bill| bill[:penalty_fee] }&.inject(0, :+).to_i
      end

      def is_closed_time?
        tnow = Time.zone.now
        @tclose <= tnow || tnow <= @topen
      end
    end
  end
end
