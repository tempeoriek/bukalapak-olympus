module Channel
  module Thor
    class Pdam < ::Channel::Thor::Base
      include PdamUtility

      PRODUCT_TYPE           = 'pdam'.freeze
      INQUIRY_URL            = '/v1/transactions/water-bills/customers'.freeze
      CREATE_TRANSACTION_URL = '/v1/transactions/water-bills'.freeze
      CONFIRM_URL            = '/v1/transactions/water-bills/order-id/'.freeze

      THOR_RESPONSE_INQUIRY_KEY     = 'water_bill_customer'.freeze
      THOR_RESPONSE_TRANSACTION_KEY = 'water_bill_transaction'.freeze

      PDAM_DETAIL_ATTRIBUTES = %i[sub_segment biller_ref usage_unit].freeze
      SUB_SEGMENT_GROUP_RATE_CONST = 'Group rate:'
      SUB_SEGMENT_GROUP_RATE_REGEX = /(Group rate: ).+\,/

      def initialize(object)
        @object = object
        @product_type = PRODUCT_TYPE
      end

      def inquiry_to_partner
        payload = {
          customer_number: @object.customer_number,
          product_code: @object.operator.code
        }

        # response = Mocks::Pdam.inquiry
        response = inquiry(payload)

        build_inquiry_response(response)
      end

      def create_transaction
        payload = {
          customer_number: @object.customer_number,
          product_code: @object.operator.code,
          order_id: @object.id.to_s,
          amount: @object.amount.to_s
        }

        response = create(payload)

        build_transaction_response(response)
      end

      def confirm_transaction
        response = get_transaction_by_id(@object.id)

        build_transaction_response(response)
      end

      def operator_id
        @object.operator.id
      end

      def product_type
        PRODUCT_TYPE
      end

      private

      def build_inquiry_response(response)
        bills_from_response = response[:bills].nil? ? [] : response[:bills]

        bills = inquiry_bills(bills_from_response)

        bukalapak_admin_charge = (bills ? bills.length * @object.operator.bukalapak_admin_charge : nil)
        partner_admin_charge = (bills ? bills.length * @object.operator.partner_admin_charge : nil)
        admin_charge = bukalapak_admin_charge + partner_admin_charge

        penalty_fee = total_penalty_fee(bills_from_response)
        segel = total_segel(bills_from_response)
        retribution = total_retribution(bills_from_response)

        response_generalizer = ResponseGeneralizer::Pdam.new

        start_meter, end_meter, stand_meter = stand_meter(bills)
        total_usage, usage_unit = usage(bills, response[:usage], bills_from_response)
        additional_details = {
          usage_unit: usage_unit
        }

        response_generalizer.customer_number = response[:customer_number].strip
        response_generalizer.customer_name = response[:customer_name].strip
        response_generalizer.address = response[:address]&.strip
        response_generalizer.penalty_fee = penalty_fee
        response_generalizer.start_bill_period = date_parser(response[:start_bill_period])
        response_generalizer.end_bill_period = date_parser(response[:end_bill_period])
        response_generalizer.partner = @object.operator.partner
        response_generalizer.amount = response[:total_price].to_i
        response_generalizer.bukalapak_admin_charge = bukalapak_admin_charge
        response_generalizer.partner_admin_charge = partner_admin_charge
        response_generalizer.bills = bills
        response_generalizer.start_usage_meter = start_meter
        response_generalizer.end_usage_meter = end_meter
        response_generalizer.usage = total_usage
        response_generalizer.operator = @object.operator
        response_generalizer.stand_meter = stand_meter
        response_generalizer.segel = segel
        response_generalizer.retribution = retribution
        response_generalizer.details = detail_attributes(response, additional_details)

        response_generalizer
      end

      def inquiry_bills(bills)
        bills.map do |bill|
          {
            bill_period: bill[:period],
            amount: calculate_bill_amount(bill),
            penalty_fee: bill[:penalty_fee].to_i,
            cubication: reformat_cubication(bill[:cubication]),
            usage: bill[:usage].split(' ')[0].to_i || 0
          }
        end
      end

      def build_transaction_response(response)
        bills_from_response = response[:bills].nil? ? [] : response[:bills]

        bills = inquiry_bills(bills_from_response)

        segel = total_segel(bills_from_response)
        retribution = total_retribution(bills_from_response)
        start_meter, end_meter, stand_meter = stand_meter(bills)

        total_usage, usage_unit = usage(bills, response[:usage], bills_from_response)
        additional_details = {
          usage_unit: usage_unit
        }

        response_generalizer = ResponseGeneralizer::Pdam.new
        response_generalizer.status = response[:status]
        response_generalizer.address = response[:address]&.strip
        response_generalizer.bills = bills
        response_generalizer.reference_number = response[:reference_number]
        response_generalizer.start_usage_meter = start_meter
        response_generalizer.end_usage_meter = end_meter
        response_generalizer.stand_meter = stand_meter
        response_generalizer.segel = segel
        response_generalizer.retribution = retribution
        response_generalizer.details = detail_attributes(response, additional_details)

        response_generalizer
      end

      def calculate_bill_amount(bill)
        # "amount" in each bill from Thor already includes the additional fees
        # thus we need to take them out to follow the standards in Olympus.
        bill[:amount].to_i - bill[:penalty_fee].to_i - bill.dig(:stamp_duty).to_i - bill.dig(:waste).to_i
      end

      def reformat_cubication(cubication)
        cubication.gsub('-', ' - ')
      end

      def stand_meter(bills)
        start_meter = 0
        end_meter = 0

        unless bills.blank?
          start_meter = bills.first[:cubication].split('-').first.to_i
          end_meter = bills.last[:cubication].split('-').last.to_i
        end
        stand_meter = "#{start_meter} - #{end_meter}"

        return [start_meter, end_meter, '-'] if start_meter.zero? && end_meter.zero?

        [start_meter, end_meter, stand_meter]
      end

      def detail_attributes(response, additional_details={})
        attrs = {}
        PDAM_DETAIL_ATTRIBUTES.map do |k|
          attrs[k] = response[k]
        end

        parse_sub_segment_attributes(attrs)

        attrs.merge(additional_details)
      end

      def parse_sub_segment_attributes(attrs)
        sub_segment = attrs[:sub_segment]
        return unless sub_segment.present?

        if sub_segment.include? SUB_SEGMENT_GROUP_RATE_CONST
          # the format being parsed is `Group rate: {group_rate}, Description: description`
          group_rate = sub_segment.match(SUB_SEGMENT_GROUP_RATE_REGEX).to_s.split(/\: /).last.chop
          attrs[:sub_segment] = group_rate
        end
      end

      def date_parser(date)
        Date.parse(date)
      rescue
        nil
      end

      def usage(bills, usage, bills_from_response)
        # need to split because the usage consists of `{value} {unit}`
        usage_value = usage.split(' ')[0]
        usage_unit = usage.split(' ')[1]
        return [usage_value.to_i, usage_unit] if usage_value.present?

        # return nil if all usage is empty string in bills from response
        return [nil, nil] if bills_from_response.all? { |b| b[:usage].empty? }

        # sum all usage in bills, when at least 1 usage is not empty in bills from response
        # treat empty usage as zero
        total_usage = bills.map { |bill| bill[:usage] }.inject(0, :+)
        usage_unit = bills_from_response.map { |bill| bill[:usage].split(' ')[1] }.find { |unit| unit != nil }
        
        [total_usage, usage_unit]
      end
    end
  end
end
