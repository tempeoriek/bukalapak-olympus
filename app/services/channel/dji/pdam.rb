module Channel
  module Dji
    class Pdam < Channel::Dji::Base
      include PdamUtility

      REFERENCE_NUMBER_KEY = 'dji:pdam:reference_number'.freeze
      UNIX_MIN_TIME = Date.strptime('197001', '%Y%m').freeze

      ## Parsers
      # key   => attribute name
      # value => attribute length

      INQUIRY_DETAIL_ATTR = {
        bill_period: 6,
        usage: 10,
        start_meter: 10,
        end_meter: 10,
        admin_fee: 12,
        penalty_fee: 12,
        amount: 12
      }.freeze

      PAYMENT_DETAIL_ATTR = {
        bill_period: 6,
        usage: 10,
        start_meter: 10,
        end_meter: 10,
        tariff: 15,
        address: 50,
        admin_fee: 12,
        penalty_fee: 12,
        amount: 12
      }.freeze

      def initialize(object, options={})
        @object = object
        @options = options.reverse_merge(DEFAULT_OPTIONS)
        @product_type = ::Postpaid::Constant::PDAM_PRODUCT
        @biller_product = snake_case(object.operator.name)
        @product_code = object.operator.code
      end

      def inquiry_to_partner
        payload = prepare_inquiry_payload
        response = inquiry(payload)
        build_inquiry_response(response)
      end

      def create_transaction
        begin
          start_time  = ::Time.current

          inquiry_payload = prepare_inquiry_payload
          inquiry_response = inquiry(inquiry_payload, { read_timeout: 90 })
        rescue ::Exceptions::BillAlreadyPaid => e
          result = ResponseGeneralizer::BpjsKesehatan.new
          result.status = PARTNER_STATUS[DJI]['failed']
          return result
        rescue Exceptions::SocketConnectionTimeout, Exceptions::Dji::ErrTimeout, Errno::ETIMEDOUT => e
          @object.update!(state: 'paid')

          log_entry = {
            payload: @object.customer_number
          }
          tags = self.class.name.split('::').map { |s| s.underscore } + %w(inquiry_payment timeout)
          LogBook.error(e.message, tags, e.backtrace.take(5), log_entry, track_id: @object.remote_transaction_id)

          duration        = ::Time.current - start_time
          status          = :timeout
          response_code   = :null
          entries = {
            action: 'inquiry_payment',
            partner: PARTNER_NAME,
            product: @product_type,
            biller_product: @biller_product,
            status: status,
            response_code: response_code
          }
          Observer.histogram(Observer::Metric::PARTNER, duration, entries)

          raise e
        end

        create_response = create(inquiry_response, @object.amount)
        build_payment_response(create_response)
      end

      def confirm_transaction
        raise ::Exceptions::PartnerTransactionNotFound unless @object.partner_transaction_id

        response = get_transaction_by_id
        build_payment_response(response)
      end

      def operator_id
        @object.operator.id
      end

      def product_type
        ::Postpaid::Constant::PDAM_PRODUCT
      end

      private

      ## BEGIN Override ##
      def host
        @host ||= Channel::Config::DJI_HOST
      end

      def port
        @port ||= Channel::Config::DJI_PORT
      end
      ## END Override ##

      def prepare_inquiry_payload
        payload = @product_code.ljust(6)
        payload += '0'
        payload += @object.customer_number.ljust(20)
        payload += '00'
        payload
      end

      def parse_bit_62(parser, message, bill_length)
        bills = []

        offset = 0
        bill_length.times do
          bill = {}
          bill[:usage] = 0
          bill[:start_meter] = 0
          bill[:end_meter] = 0
          bill[:tariff] = 0
          bill[:address] = "-"
          bill[:admin_fee] = 0
          bill[:penalty_fee] = 0

          ## Parsing
          parser.each do |attribute, length|
            bill[attribute] = message[offset..offset+length-1]
            offset += length
          end

          ## Postprocessing
          bill[:address].strip!
          bill[:start_meter] = bill[:start_meter].to_i
          bill[:end_meter] = bill[:end_meter].to_i
          bill[:cubication] = "#{bill[:start_meter]}-#{bill[:end_meter]}"
          bill[:admin_fee] = bill[:admin_fee].to_i
          bill[:penalty_fee] = bill[:penalty_fee].to_i
          bill[:amount] = bill[:amount].to_i
          begin
            period = Date.strptime(bill[:bill_period], '%Y%m')
            bill[:bill_period] = period < UNIX_MIN_TIME ? nil : period
          rescue ArgumentError => e
            log_invalid_date_error(message, bill_length)
            raise e
          end

          bills << bill
        end

        bills
      end

      def build_inquiry_response(response)
        inquiry_summary = parse_bit_48(response[48])
        bills = parse_bit_62(INQUIRY_DETAIL_ATTR, response[62], inquiry_summary[:bill_length].to_i)

        result = ResponseGeneralizer::Pdam.new

        result.customer_number = inquiry_summary[:customer_number].strip
        result.customer_name = inquiry_summary[:customer_name].strip
        result.penalty_fee = total_penalty_fee(bills).to_i
        result.start_bill_period = start_bill_period(bills)
        result.end_bill_period = end_bill_period(bills)
        result.partner = DJI
        result.amount = response[4].to_i
        result.bills = bills
        result.address = bills&.first&.[](:address)
        result.usage = calculate_total_usage(bills)
        result.operator = @object.operator

        if bills.present?
          result.start_usage_meter = bills.first[:start_meter]
          result.end_usage_meter = bills.last[:end_meter]
          result.bukalapak_admin_charge = bills.length * @object.operator.bukalapak_admin_charge
          result.partner_admin_charge = bills.length * @object.operator.partner_admin_charge
        else
          result.start_usage_meter = 0
          result.end_usage_meter = 0
          result.bukalapak_admin_charge = nil
          result.partner_admin_charge = nil
        end

        result
      end

      def build_payment_response(response)
        result = ResponseGeneralizer::Pdam.new
        result.status = PARTNER_STATUS[DJI][transaction_status(response[39])]
        result.partner_transaction_id = response[37]

        if result.status == SUCCESS
          payment_summary = parse_bit_48(response[48])
          bills = parse_bit_62(PAYMENT_DETAIL_ATTR, response[62], payment_summary[:bill_length].to_i)

          result.address = bills&.first&.[](:address)
          result.bills = bills
        end

        result
      end

      def increment_unique_number
        Keystore.increment(REFERENCE_NUMBER_KEY)
      end

      # This is a temporary log to investigate a bug with the bill_period parsing
      # TODO: remove or make the log more general
      def log_invalid_date_error(bit_62_message, bill_length)
        tags = %w[olympus pdam dji invalid_date error]
        logs = {
          payload: prepare_inquiry_payload,
          bit_62_response: bit_62_message,
          bill_length: bill_length
        }
        log_entry = ::Context.new.log_entry("Invalid date", tags, logs)
        Logger2.error(log_entry)
      end
    end
  end
end
