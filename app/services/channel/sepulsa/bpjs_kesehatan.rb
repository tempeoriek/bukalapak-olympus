module Channel
  module Sepulsa
    class BpjsKesehatan < Channel::Sepulsa::Base
      PRODUCT_ID = ENV['BPJS_KESEHATAN_PRODUCT'].to_i.freeze

      #circuit box configuration
      CIRCUITBOX_SLEEP_WINDOW = 60
      CIRCUITBOX_TIME_WINDOW = 30
      CIRCUITBOX_VOLUME_THRESHOLD = 10
      CIRCUITBOX_ERROR_THRESHOLD = 50

      CIRCUITBOX_CONFIGURATION = {
        exceptions: [Exceptions::SocketConnectionTimeout, RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT],
        sleep_window: CIRCUITBOX_SLEEP_WINDOW,
        time_window: CIRCUITBOX_TIME_WINDOW,
        volume_threshold: CIRCUITBOX_VOLUME_THRESHOLD,
        error_threshold: CIRCUITBOX_ERROR_THRESHOLD
      }.freeze

      # object can only be :
      # - form object
      # - transaction object
      def initialize(object)
        @object = object
      end

      def inquiry_to_partner
        payload = {
          product_id: PRODUCT_ID,
          customer_number: @object.customer_number,
          payment_period: @object.payment_period
        }

        if ::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa.active?
          response = ::CircuitBreaker.run(:bpjs_sepulsa_inquiry, CIRCUITBOX_CONFIGURATION) do
            inquiry(payload)
          end
        else
          response = inquiry(payload)
        end

        build_inquiry_response(response)
      end

      def create_transaction
        payload = {
          product_id: PRODUCT_ID,
          customer_number: @object.customer_number,
          payment_period: @object.payment_period,
          amount: @object.amount - @object.admin_charge,
          order_id: @object.order_id
        }

        if ::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa.active?
          response = ::CircuitBreaker.run(:bpjs_sepulsa_transaction, CIRCUITBOX_CONFIGURATION) do
            create(payload)
          end
        else
          response = create(payload)
        end

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
        response = get_transaction_by_id(@object.partner_transaction_id, BPJS_KESEHATAN_PRODUCT)
        build_transaction_response(response)
      end

      def confirm_with_order_id
        response = get_transaction_by_order_id(@object.order_id, BPJS_KESEHATAN_PRODUCT)
        build_transaction_response(response)
      end

      def product_type
        BPJS_KESEHATAN_PRODUCT
      end

      private

      def build_inquiry_response(response)
        name_and_family_member_count = response[:name].rpartition('(')

        result = ResponseGeneralizer::BpjsKesehatan.new
        result.customer_number = response[:no_va].strip
        result.customer_name = name_and_family_member_count.first.strip
        result.amount = response[:premi].to_i +  @object.partner_object.admin_charge
        result.bukalapak_admin_charge =  @object.partner_object.bukalapak_admin_charge
        result.partner_admin_charge =  @object.partner_object.partner_admin_charge
        result.family_member_count = name_and_family_member_count.last.gsub(/\D/, "").to_i
        result.payment_period = response[:periode].rjust(2, '0')
        result.branch_name = response[:nama_cabang].strip
        result.partner = SEPULSA
        result.paid_until = {
          month: @object.month,
          year: @object.year
        }

        result
      end

      def build_transaction_response(response)
        result = ResponseGeneralizer::BpjsKesehatan.new
        result.partner_transaction_id = response[:partner_transaction_id]
        result.status = response[:status]
        result.info = response[:info_text]
        result.reference_number = response[:sw_reff]

        result
      end
    end
  end
end
