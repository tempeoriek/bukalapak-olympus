module Channel
  module BNI
    class CreditCardBill < Channel::BNI::Base
      include ApplicationHelper
      include CreditCardBillHelper

      # list fitur Id
      # FTR430 : Credit Card BNI Inquiry
      # FTR431 : Credit Card BNI Payment
      # FTR432 : Credit Card Non‐BNI Payment
      CC_INQUIRY_FEATURE_ID = "FTR430".freeze
      CC_PAYMENT_BNI_FEATURE_ID = "FTR431".freeze
      CC_PAYMENT_NON_BNI_FEATURE_ID = "FTR432".freeze
      CLOSE_TIME = Time.parse('16:59').utc # 23:59 in utc+7
      OPEN_TIME = Time.parse('17:10').utc # 00:10 in utc+7
      BNI_ERROR_NUMBER_TIMEOUT = "9999".freeze
      # object can only be :
      # - form object
      # - transaction object
      def initialize(object)
        @object = object
        @track_id = @object.respond_to?(:id) ? @object.id : nil
        @biller_product = snake_case(object.biller.name)
        @product_type = 'credit-card-bill'
        @request_type = 'credit-card-bill-transaction'
      end

      def inquiry_to_partner
        start_time = ::Time.current

        raise ::Exceptions::ClosedTimeError.new(CLOSE_TIME, OPEN_TIME) if closed_time?

        if @object.biller.biller_code == BNI_BILLER_CODE
          generate_payload("inquiry")

          response = make_request

          if response[:error].nil? || response[:error]
            response_code = "#{response[:errorNum]&.to_s&.ljust(4, ' ')} - #{response[:message]&.to_s}"

            log_and_metric { ['inquiry', response, response_code, :failed] }
            raise_error(response[:errorNum])
          end

          result = credit_card_bill_inquiry_response(response)
        else
          result = ResponseGeneralizer::CreditCardBill.new
          result.customer_number = @object.customer_number
          result.biller = @object.biller
          result.partner = @object.biller.partner
          result.status = 'success'
          result.response_code = 'success'
        end

        masking(result, @object.biller.biller_code)
      ensure
        duration      = ::Time.current - start_time
        status        = result ? result.status.to_sym : :error
        response_code = result ? result.response_code : 'error'
        entries = {
          action: 'inquiry',
          partner: 'bni',
          product: @product_type,
          biller_product: @biller_product,
          status: status,
          response_code: response_code
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, entries)
      end

      def create_transaction
        start_time = ::Time.current

        generate_payload("payment")

        response = make_request

        failed_response = validate_payment_response(response)
        return failed_response unless failed_response.blank?

        log_and_metric do
          ['payment', response, '0    - success', :success]
        end

        result = ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = SUCCESS
          res.response_code = BNI_SUCCESS
          res.partner_journal_number = response[:data][:journal]
          res.partner_financial_journal_number = response[:data][:financialJournal]
        end
      rescue RestClient::Exception, Exceptions::BNI::TimeoutResponse => e
        Keystore.expire(BNI_ACCESS_TOKEN_KEY)

        log_and_metric do
          ['payment', response, '-1   - timeout', :failed]
        end

        result = ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = PENDING
          res.response_code = BNI_TIMEOUT
        end
      ensure
        duration = ::Time.current - start_time
        if !failed_response.blank?
          status = :failed
          response_code = failed_response.response_code
        else
          status = result ? :success : :error
          response_code = result ? result.response_code : 'error'
        end
        tags = {
          action: 'payment',
          partner: 'bni',
          product: @product_type,
          biller_product: @biller_product,
          status: status,
          response_code: response_code
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, tags)
      end

      def get_transaction_list
        generate_payload("list")

        response = make_request

        unless response[:code].to_s == "1"
          log_and_metric { ['list', response, response[:code], :failed] }
          raise ::Exception::PartnerIssue.new("Get transaction list failed")
        end

        log_and_metric { ['list', response, response[:code], :success] }

        response[:data]
      end

      def get_transaction_detail
        generate_payload("detail")

        response = make_request

        unless response[:code].to_s == "1"
          log_and_metric { ['detail', response, response[:code], :failed] }
          raise ::Exception::PartnerIssue.new("Get transaction detail failed")
        end

        log_and_metric { ['detail', response, response[:code], :success] }

        result = ResponseGeneralizer::CreditCardBill.new do |res|
          res.reference_number = response[:data].first[:keterangan][:data][:reffNum]
          res.partner_transaction_id = @object.partner_transaction_id
          res.partner_financial_journal_number = response[:data].first[:keterangan][:data][:financialJournal]
          res.partner_journal_number = response[:data].first[:keterangan][:data][:journal]
          res.response_code = BNI_SUCCESS
          res.status = SUCCESS
        end
      end

      def confirm_transaction
        raise ::Exceptions::ManualCheckError.new("BNI")
      end

      def confirm_with_order_id
        nil
      end

      private

      def validate_payment_response(response)
        raise Exceptions::BNI::TimeoutResponse.new if response.dig(:data, :errorNum) == BNI_ERROR_NUMBER_TIMEOUT

        return {} if response[:data] && !response[:data][:error]
        response = response[:data] ? response[:data] : response

        log_and_metric do
          response_code = "#{response[:errorNum]&.to_s&.ljust(4, ' ')} - #{response[:message]&.to_s}"
          ['payment', response, response_code, :failed]
        end

        check_error(response)

        Keystore.expire(BNI_ACCESS_TOKEN_KEY)

        result = ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = FAILED
          res.response_code = response[:errorNum]&.to_s
        end
      end

      def generate_payload(payload_type)
        @payload = {}
        case payload_type
        when "inquiry"
          @request_type = 'credit-card-bill-inquiry'
          @payload = {
            typereq: "trans",
            dealerId: DEALER_ID,
            fiturId: CC_INQUIRY_FEATURE_ID,
            data: {
              clientId: "IBOC",
              reffNum: generate_reference_number,
              cardNum: @object.customer_number
            }
          }
        when "payment"
          @request_type = 'credit-card-bill-payment'
          @payload = {
            typereq: "trans",
            dealerId: DEALER_ID,
            fiturId: CC_PAYMENT_BNI_FEATURE_ID,
            data: {
              kode_mitra: KODE_MITRA,
              kode_loket: KODE_LOKET,
              kode_cabang: KODE_CABANG,
              clientId: "IBOC",
              reffNum: @object.reference_number,
              cardNum: @object.card_number,
              accountNum: ACCOUNT_NUM,
              amount: @object.base_amount,
              pin_transaksi: PIN_TRANSAKSI
            }
          }
          unless @object.biller.biller_code == BNI_BILLER_CODE
            @payload[:fiturId] = CC_PAYMENT_NON_BNI_FEATURE_ID
            @payload[:data][:bankCode] = @object.biller.biller_code
          end
          @payload
        when "list"
          @request_type = 'credit-card-bill-list'
          @payload = {
            typereq: "trans",
            dealerId: DEALER_ID,
            fiturId: BNI_TRANSCTION_LIST_FEATURE_ID,
            data: {
              kode_mitra: KODE_MITRA,
              kode_loket: KODE_LOKET,
              kode_cabang: KODE_CABANG,
              dari: @object.start_date,
              sampai: @object.end_date
            }
          }
        when "detail"
          @request_type = 'credit-card-bill-detail'
          @payload = {
            typereq: "trans",
            dealerId: DEALER_ID,
            fiturId: BNI_TRANSACTION_DETAIL_FEATURE_ID,
            data: {
              transaksi_id: @object.partner_transaction_id.to_s
            }
          }
        else
          Raise "payload_type not defined"
        end
      end

      def credit_card_bill_inquiry_response(response)
        biller = @object.biller
        amount = response[:lastBillAmountSign] == "+" ? response[:lastBillAmount].to_i : response[:lastBillAmount].to_i * -1
        result = ResponseGeneralizer::CreditCardBill.new do |res|
          res.customer_number = response[:cardNum]
          res.customer_name = response[:cardHolder]
          res.displayed_name = response[:cardHolder]
          res.statement_date = Converter::StringToDate.convert(response[:statementDate], string_format: DDMMYYYY)
          res.due_date = Converter::StringToDate.convert(response[:dueDate], string_format: DDMMYYYY)
          res.amount = amount
          res.minimum_payment = response[:minPayment].to_i
          res.biller = biller
          res.partner = biller.partner
          res.status = 'success'
          res.response_code = 'success'
        end
      end

      def generate_reference_number
        date = Time.now.in_time_zone.strftime("%Y%m%d%H%M%S%5N")
        "#{date}#{Random.rand(10)}#{KODE_LOKET}"
      end

      def closed_time?
        tnow = Time.now.utc
        CLOSE_TIME <= tnow && tnow <= OPEN_TIME
      end
    end
  end
end
