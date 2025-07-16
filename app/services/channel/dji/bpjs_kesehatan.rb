module Channel
  module Dji
    class BpjsKesehatan < Channel::Dji::Base
      HOST = Channel::Config::DJI_MULTIBILLER_HOST
      PORT = Channel::Config::DJI_MULTIBILLER_PORT
      REFERENCE_NUMBER_KEY = 'dji:bpjs_kesehatan:reference_number'.freeze

      # object can only be :
      # - form object
      # - transaction object
      def initialize(object, options={})
        @object = object
        @options = options.reverse_merge(DEFAULT_OPTIONS)
        @product_type = ::Postpaid::Constant::BPJS_KESEHATAN_PRODUCT
        @product_code = Channel::Config::DJI_BPJS_KESEHATAN_PRODUCT_CODE
      end

      def inquiry_to_partner
        # payload detail refer to https://bukalapak.atlassian.net/wiki/spaces/VP/pages/765770368/Partner+Api+Doc
        # `Spesifikasi Teknis DJI-Multibiller (1).pdf`, inquiry bit48 section
        payload = prepare_inquiry_payload
        response = inquiry(payload)

        build_inquiry_response(response)
      end

      def create_transaction
        begin
          inquiry_payload = prepare_inquiry_payload
          inquiry_response = inquiry(inquiry_payload, retry_when_timeout: true)
        rescue ::Exceptions::BillAlreadyPaid => e
          result = ResponseGeneralizer::BpjsKesehatan.new
          result.status = PARTNER_STATUS[DJI]['failed']
          return result
        end
        create_response = create(inquiry_response, @object.amount)

        if success?(create_response)
          build_transaction_response(create_response)
        else
          build_failed_response(create_response)
        end
      end

      def confirm_transaction
        raise ::Exceptions::PartnerTransactionNotFound unless @object.partner_transaction_id

        response = get_transaction_by_id

        if success?(response)
          build_transaction_response(response)
        else
          build_failed_response(response)
        end
      end

      def product_type
        ::Postpaid::Constant::BPJS_KESEHATAN_PRODUCT
      end

      private

      def build_payment_message(inquiry_data, amount)
        super(inquiry_data, amount) do |message|
          message[120] = @object.phone_number
        end
      end

      def success?(response)
        response[39] == "00"
      end

      def prepare_inquiry_payload
        payload = ''
        payload += @product_code.ljust(6)
        payload += '0'
        payload += @object.customer_number.ljust(20)
        payload += @object.payment_period.ljust(2)
        payload
      end

      def inquiry_detail(message)
        result = {}
        DJI_BPJS_KESEHATAN_INQUIRY_DETAIL_ATTR_PRE.each do |k,v|
          result[k] = message[0..v-1]
          message = message[v..-1]
        end

        members = []
        result[:family_member_count].to_i.times do
          member = {}
          DJI_BPJS_KESEHATAN_MEMBER_DETAIL_ATTR_MEMBER.each do |k,v|
            member[k] = message[0..v-1].strip
            message = message[v..-1]
          end

          members << member
        end
        result[:family_members] = members
        DJI_BPJS_KESEHATAN_INQUIRY_DETAIL_ATTR_POST.each do |k,v|
          result[k] = message[0..v-1]
          message = message[v..-1]
        end

        result
      end

      def payment_detail(message)
        result = {}
        DJI_BPJS_KESEHATAN_PAYMENT_DETAIL_ATTR.each do |k,v|
          result[k] = message[0..v-1]
          message = message[v..-1]
        end
        result
      end


      def build_inquiry_response(response)
        inquiry_summary = parse_bit_48(response[48])
        inquiry_detail = inquiry_detail(response[62])
        result = ResponseGeneralizer::BpjsKesehatan.new
        result.customer_number = inquiry_summary[:customer_number].strip
        result.customer_name = inquiry_summary[:customer_name].strip
        result.amount = response[4].to_i
        result.bukalapak_admin_charge = @object.partner_object.bukalapak_admin_charge
        result.partner_admin_charge = @object.partner_object.partner_admin_charge
        result.family_member_count = inquiry_detail[:family_member_count].to_i

        family_members = format_family_members(inquiry_detail[:family_members])

        result.family_members = family_members
        result.payment_period = inquiry_detail[:payment_period].rjust(2, '0')
        result.branch_name = inquiry_detail[:branch_name]&.strip
        result.partner = DJI_BPJS
        result.paid_until = {
          month: @object.month,
          year: @object.year
        }

        result
      end

      def build_transaction_response(response)
        payment_detail = payment_detail(response[62])
        result = ResponseGeneralizer::BpjsKesehatan.new
        result.reference_number = payment_detail[:reference]&.strip
        result.info = payment_detail[:info]&.strip
        result.partner_transaction_id = response[37].to_s
        result.status = PARTNER_STATUS[DJI][transaction_status(response[39])]

        result
      end

      def build_failed_response(response)
        result = ResponseGeneralizer::BpjsKesehatan.new
        result.partner_transaction_id = response[37].to_s
        result.status = PARTNER_STATUS[DJI][transaction_status(response[39])]
        result
      end

      def build_failed_response(response)
        result = ResponseGeneralizer::BpjsKesehatan.new
        result.partner_transaction_id = response[37].to_s
        result.status = PARTNER_STATUS[DJI][transaction_status(response[39])]
        result
      end

      def format_family_members(family_members)
        family_members.map do |family_member|
          {
            member_number: family_member[:member_number].strip,
            name: family_member[:name].strip,
            balance: family_member[:balance].to_i,
            premium: family_member[:premium].to_i
          }
        end
      end

      def increment_unique_number
        Keystore.increment(REFERENCE_NUMBER_KEY)
      end
    end
  end
end
