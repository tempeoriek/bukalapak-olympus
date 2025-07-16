module Channel
  module Sepulsa
    class PhoneCredit < Channel::Sepulsa::Base
      def initialize(object)
        @object = object
        @biller_product = snake_case(object.provider.provider)
      end

      def inquiry_to_partner
        payload = {
          product_id: @object.provider.partner_product_id,
          customer_number: @object.customer_number,
          product_type: PHONE_CREDIT_PRODUCT
        }
        response = inquiry(payload)

        build_inquiry_response(response)
      end

      def create_transaction
        payload = {
          product_id: @object.provider.partner_product_id,
          customer_number: @object.phone_number,
          product_type: PHONE_CREDIT_PRODUCT,
          amount: @object.amount - @object.admin_charge,
          order_id: @object.order_id
        }
        response = create(payload)

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
        response = get_transaction_by_id(@object.partner_transaction_id, PHONE_CREDIT_PRODUCT)
        build_transaction_response(response)
      end

      def confirm_with_order_id
        response = get_transaction_by_order_id(@object.order_id, PHONE_CREDIT_PRODUCT)
        build_transaction_response(response)
      end

      def get_auth
        if Toggles::PhoneCreditPostpaidMitraAuth.active? && @object.is_mitra?
          MITRA_AUTH
        else
          AUTH
        end
      end

      def product_type
        PHONE_CREDIT_PRODUCT
      end

      private

      def build_inquiry_response(response)
        provider = @object.provider
        bill_period = bill_period(response[:bill_periode].strip.split(','))
        admin_charge = provider.partner_admin_charge + provider.bukalapak_admin_charge
        total_amount = response[:bill_amount].to_i + admin_charge

        response_generalizer = ResponseGeneralizer::PhoneCreditPostpaid.new

        response_generalizer.customer_number = response[:customer_no].strip
        response_generalizer.customer_name = response[:customer_name].strip
        response_generalizer.reference_no = response[:reference_no].strip
        response_generalizer.bill_count = response[:bill_count].to_i
        response_generalizer.bill_period = bill_period
        response_generalizer.bill_amount = response[:bill_amount].to_i
        response_generalizer.partner_admin_charge = provider.partner_admin_charge
        response_generalizer.bukalapak_admin_charge = provider.bukalapak_admin_charge
        response_generalizer.bukalapak_commission = provider.bukalapak_commission
        response_generalizer.admin_charge = admin_charge
        response_generalizer.total_amount = total_amount
        response_generalizer.provider_id = provider[:id]
        response_generalizer.provider_name = provider[:provider]
        response_generalizer.provider_product_name = provider[:product_name]
        response_generalizer.provider_logo_url = provider[:logo_url]
        response_generalizer.partner = provider[:partner]

        response_generalizer
      end

      def build_transaction_response(response)
        response_generalizer = ResponseGeneralizer::PhoneCreditPostpaid.new
        response_generalizer.partner_transaction_id = response[:partner_transaction_id]
        response_generalizer.status = response[:status]

        response_generalizer
      end

      def bill_period(periods)
        periods.map do |period|
          ::Converter::StringToDate.convert(period, string_format: YYYYMM)
        end
      end
    end
  end
end
