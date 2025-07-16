# frozen_string_literal: true

module Channel
  module NewBNI
    module Request
      #  PaymentBNI will process credit card bill transaction with biller BNI
      #  parameters:
      #  CreditCardBillTransaction: <CreditCardBillTransaction> # credit card bill transaction model
      #
      #  response from PaymentBNI
      #  - {} object of ResponseGeneralizer::CreditCardBill.
      class PaymentBNI < Base
        include ApplicationHelper

        BNI_ERROR_NUMBER_TIMEOUT = ['9126', '0008'].freeze
        TRANSACTION_URL = Channel::Config::NEW_BNI_PAYMENT_BNI_URL

        # object can only be :
        # - transaction object
        def initialize(transaction)
          @transaction = transaction
          @track_id = @transaction.respond_to?(:id) ? @transaction.id : nil
        end

        def perform
          start_time = ::Time.current

          @request_payload = generate_request_payload

          response = make_request

          failed_response = validate_payment_response(response)
          return failed_response unless failed_response.blank?

          log_and_metric do
            ['payment', response, '0    - success', :success]
          end

          parsed_response = response.dig("NS1:body", "sw:transactionResponse", :response)
          result = ResponseGeneralizer::CreditCardBill.new do |res|
            res.status = SUCCESS
            res.response_code = BNI_SUCCESS
            res.partner_journal_number = parsed_response.dig(:switcherJournal)
            res.partner_financial_journal_number = parsed_response.dig(:financialJournal)
          end
        rescue RestClient::Exception, Exceptions::BNI::TimeoutResponse => e
          Keystore.expire(NEW_BNI_ACCESS_TOKEN_KEY)

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
            partner: 'new_bni',
            product: PRODUCT_TYPE,
            biller_product: snake_case(@transaction.biller.name),
            status: status,
            response_code: response_code
          }
          Observer.histogram(Observer::Metric::PARTNER, duration, tags)
        end

        private

        def generate_request_payload
          payload = {
            cardNum: @transaction.card_number,
            accountNum: ACCOUNT_NUM,
            amount: @transaction.base_amount.to_s
          }
          payload.merge!(signature: generate_signature(payload))
          payload
        end

        def make_request
          @start_time = ::Time.now

          JSON.parse(::Channel::Connection::Http.post(transaction_url(TRANSACTION_URL), nil, @request_payload, {'X-API-Key': API_KEY})).with_indifferent_access
        end

        def validate_payment_response(response)
          raise Exceptions::BNI::TimeoutResponse.new if BNI_ERROR_NUMBER_TIMEOUT.include?(response.dig(:"soapenv:Body", :"soapenv:Fault", :detail, :"pa:Fault_element", :errorCode))

          return {} if response["NS1:body"] && !response.dig(:"soapenv:Body", :"soapenv:Fault")
          response = response.dig(:"soapenv:Body", :"soapenv:Fault", :detail)

          log_and_metric do
            response_code = "#{response.dig(:"pa:Fault_element", :errorCode)} - #{response.dig(:"pa:Fault_element", :errorDescription)}"
            ['payment', response, response_code, :failed]
          end

          Keystore.expire(NEW_BNI_ACCESS_TOKEN_KEY)

          result = ResponseGeneralizer::CreditCardBill.new do |res|
            res.status = FAILED
            res.response_code = response.dig(:"pa:Fault_element", :errorCode)&.to_s
          end
        end

        def log_and_metric(&block)
          action, response, response_code, status = block.call

          tags = ['credit_card_bill', action, status.to_s, 'new_bni']
          message = log_message(transaction_url(TRANSACTION_URL), @request_payload, response)
          log_request(tags, message, @track_id)
        end

        def log_message(url, request, response)
          duration = @start_time ? (::Time.now - @start_time).round(2) : -1
          CreditCardBillHelper.hash_cc_number_in_object(request[:data], [:cardNum])
          {
            url: url,
            duration: duration,
            payload: request,
            response: response
          }.to_s
        end
      end
    end
  end
end
