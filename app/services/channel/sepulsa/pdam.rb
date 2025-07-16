module Channel
  module Sepulsa
    class Pdam < Channel::Sepulsa::Base
      include PdamUtility

      PRODUCT_ID = ENV['PDAM_PRODUCT'].to_i.freeze

      # object can only be :
      # - form object
      # - transaction object
      def initialize(object)
        @object = object
        @biller_product = snake_case(object.operator.name)
      end

      def inquiry_to_partner
        payload = {
          product_id: PRODUCT_ID,
          customer_number: @object.customer_number,
          operator_code: @object.operator.code,
          product_type: PDAM_PRODUCT
        }
        response = inquiry(payload)

        build_inquiry_response(response)
      end

      def create_transaction
        payload = {
          product_id: PRODUCT_ID,
          customer_number: @object.customer_number,
          operator_code: @object.operator.code,
          amount: @object.amount - @object.admin_charge,
          order_id: @object.order_id,
          product_type: PDAM_PRODUCT
        }

        response = create(payload, @object.remote_transaction_id)

        build_transaction_response(response)
      end

      def confirm_transaction
        if @object.partner_transaction_id.nil?
          confirm_with_order_id
        else
          confirm_with_partner_transaction_id
        end
      end

      def confirm_with_partner_transaction_id
        response = get_transaction_by_id(@object.partner_transaction_id, PDAM_PRODUCT)

        build_transaction_response(response)
      end

      def confirm_with_order_id
        response = get_transaction_by_order_id(@object.order_id, PDAM_PRODUCT)

        build_transaction_response(response)
      end

      def product_type
        PDAM_PRODUCT
      end

      def operator_id
        @object.operator.id
      end

      private
      def build_inquiry_response(response)
        bills = inquiry_bills(response[:bills])
        bukalapak_admin_charge = (bills ? bills.length * @object.operator.bukalapak_admin_charge : nil)
        partner_admin_charge = (bills ? bills.length * @object.operator.partner_admin_charge : nil)
        admin_charge = bukalapak_admin_charge + partner_admin_charge
        penalty_fee = total_penalty_fee(bills)

        start_meter = 0
        end_meter = 0
        if !bills.blank?
          start_meter = bills.first[:cubication].split('-').first.to_i
          end_meter = bills.last[:cubication].split('-').last.to_i
        end

        response_generalizer = ResponseGeneralizer::Pdam.new

        response_generalizer.customer_number = response[:idpel].strip
        response_generalizer.customer_name = response[:name].strip
        response_generalizer.penalty_fee = penalty_fee
        response_generalizer.start_bill_period = start_bill_period(bills)
        response_generalizer.end_bill_period = end_bill_period(bills)
        response_generalizer.partner = SEPULSA
        response_generalizer.amount = calculate_total_amount(bills) + admin_charge + penalty_fee
        response_generalizer.bukalapak_admin_charge = bukalapak_admin_charge
        response_generalizer.partner_admin_charge = partner_admin_charge
        response_generalizer.bills = bills
        response_generalizer.start_usage_meter = start_meter
        response_generalizer.end_usage_meter = end_meter
        response_generalizer.usage = calculate_total_usage(bills)
        response_generalizer.operator = @object.operator

        response_generalizer
      end

      def build_transaction_response(response)
        bills = inquiry_bills(response[:bills])
        response_generalizer = ResponseGeneralizer::Pdam.new

        response_generalizer.partner_transaction_id = response[:partner_transaction_id]
        response_generalizer.status = response[:status]
        response_generalizer.bills = bills

        response_generalizer
      end

      def inquiry_bills(bills)
        bills&.map do |bill|
          {
            # convert YYYYMM format to YYYY-MM
            bill_period: ::Converter::StringToDate.convert(bill[:bill_date][0], string_format: YYYYMM),
            amount: bill[:bill_amount][0].to_i,
            penalty_fee: bill[:penalty][0].to_i,
            cubication: bill[:kubikasi][0],
            usage: bill_usage(bill[:kubikasi][0])
          }
        end
      end
    end
  end
end
