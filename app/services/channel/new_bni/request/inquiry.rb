# frozen_string_literal: true

module Channel
  module NewBNI
    module Request
      class Inquiry < Base
        include ApplicationHelper
        include CreditCardBillHelper

        BNI_ERROR_NUMBER_TIMEOUT = ['9126', '0008'].freeze
        INQUIRY_URL = Channel::Config::NEW_BNI_INQUIRY_URL
        CLOSE_TIME = Time.parse('16:59').utc # 23:59 in utc+7
        OPEN_TIME = Time.parse('17:10').utc # 00:10 in utc+7
        
        def initialize(object)
          @object = object
          @track_id = @object.respond_to?(:id) ? @object.id : nil
        end

        def perform
          start_time = ::Time.current

          raise ::Exceptions::ClosedTimeError.new(CLOSE_TIME, OPEN_TIME) if closed_time?

          if @object.biller.biller_code == BNI_BILLER_CODE
            @request_payload = generate_inquiry_payload

            response = make_request

            failed_response = validate_inquiry_response(response)
            return failed_response unless failed_response.blank?

            result = credit_card_bill_new_inquiry_response(response)
          else
            result = inquiry_response_non_bni
          end

          masking(result, @object.biller.biller_code)
        rescue RestClient::Exception, Exceptions::BNI::TimeoutResponse => e
          Keystore.expire(NEW_BNI_ACCESS_TOKEN_KEY)

          log_and_metric do
            ['inquiry', response, '-1   - timeout', :failed]
          end

          result = ResponseGeneralizer::CreditCardBill.new do |res|
            res.status = PENDING
            res.response_code = BNI_TIMEOUT
          end

        ensure
          duration      = ::Time.current - start_time
          if !failed_response.blank?
            status = :failed
            response_code = failed_response.response_code
          else
            status = result ? :success : :error
            response_code = result ? result.response_code : 'error'
          end
          entries = {
            action: 'inquiry',
            partner: 'new_bni',
            product: PRODUCT_TYPE,
            biller_product: snake_case(@object.biller.name),
            status: status,
            response_code: response_code
          }
          Observer.histogram(Observer::Metric::PARTNER, duration, metric_tags(action: :request_token, status: status))
        end

        private

        def generate_inquiry_payload
          payload = {
            cardNum: @object.customer_number
          }
          payload.merge!(signature: generate_signature(payload))
          payload
        end

        def make_request
          @start_time = ::Time.now

          JSON.parse(::Channel::Connection::Http.post(inquiry_url, nil, @request_payload, {'X-API-Key': API_KEY})).with_indifferent_access
        end

        def inquiry_url
          query = {
            access_token: retrieve_access_token
          }
          "#{INQUIRY_URL}?#{query.to_query}"
        end

        def credit_card_bill_new_inquiry_response(response)
          biller = @object.biller
          parsed_response = response.dig("NS1:body", "sw:transactionResponse", "response", "content")
          amount = parsed_response.dig("lastBillAmountSign", "#text") == "+" ? parsed_response.dig("lastBillAmount", "#text").to_i : parsed_response.dig("lastBillAmount", "#text").to_i * -1
          result = ResponseGeneralizer::CreditCardBill.new do |res|
            res.customer_number = parsed_response.dig("cardNum", "#text")
            res.customer_name = parsed_response.dig("cardHolder", "#text")
            res.displayed_name = parsed_response.dig("cardHolder", "#text")
            res.statement_date = Converter::StringToDate.convert(parsed_response.dig("statementDate", "#text"), string_format: DDMMYYYY)
            res.due_date = Converter::StringToDate.convert(parsed_response.dig("dueDate", "#text"), string_format: DDMMYYYY)
            res.amount = amount
            res.minimum_payment = parsed_response.dig("minPayment", "#text").to_i
            res.biller = biller
            res.partner = biller.partner
            res.status = 'success'
            res.response_code = 'success'
          end
        end

        def closed_time?
          tnow = Time.now.utc
          CLOSE_TIME <= tnow && tnow <= OPEN_TIME
        end

        def validate_inquiry_response(response)
          raise Exceptions::BNI::TimeoutResponse.new if BNI_ERROR_NUMBER_TIMEOUT.include?(response.dig(:"soapenv:Body", :"soapenv:Fault", :detail, :"pa:Fault_element", :errorCode))

          return {} if response["NS1:body"] && !response.dig(:"soapenv:Body", :"soapenv:Fault")
          response = response.dig(:"soapenv:Body", :"soapenv:Fault", :detail)

          log_and_metric do
            response_code = "#{response.dig(:"pa:Fault_element", :errorCode)} - #{response.dig(:"pa:Fault_element", :errorDescription)}"
            ['inquiry', response, response_code, :failed]
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
          message = log_message(inquiry_url, @request_payload, response)
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

        def inquiry_response_non_bni
          result = ResponseGeneralizer::CreditCardBill.new
          result.customer_number = @object.customer_number
          result.biller = @object.biller
          result.partner = @object.biller.partner
          result.status = 'success'
          result.response_code = 'success'

          result
        end
      end
    end
  end
end
