# frozen_string_literal: true

module Channel
  module Visa
    class Base
      include PostpaidTransactionUtility
      include CreditCardBillHelper

      PARTNER_TAG = %w[partner visa]

      RC_ACCEPTED = '100'
      RC_ERROR    = '101'
      RC_DECLINED = '102'
      RC_PREFIX   = 'VISA_'

      # Dummy placeholder for billing detail and card expiry date.
      # As the agreement with Visa, the configuration below will be
      # used in production env as well.
      BILL_TO_FORENAME = 'NoReal'
      BILL_TO_SURNAME = 'Name'
      BILL_TO_EMAIL = 'null@cybersource.com'
      FUTURE_EXPIRY_MONTHS = 60

      def secure_acceptance_token
        start_time = ::Time.current
        sac = CyberSource::SecureAcceptanceCheckout.new(
          bill_to_forename: bill_to_forename,
          bill_to_surname:  bill_to_surname,
          bill_to_email:    bill_to_email,
          card_number:      @object.customer_number,
          card_expiry_date: card_expiry_date,
          amount:           base_amount
        )
        result = sac.tokenize_card

        local_signature = sac.signature(payload: result.with_indifferent_access)
        validate_token_result(result, local_signature)

        result

      rescue RestClient::Exceptions::Timeout => e
        rc = 'timeout'
      rescue => e
        raise e
      ensure
        log_and_metric(action:        :get_token,
                       url:           sac&.url,
                       payload:       sac&.payload,
                       result:        result&.except(:payment_token, :signature, :request_token),
                       duration:      ::Time.current - start_time,
                       response_code: result&.[](:reason_code) || rc,
                       error:         e )
      end

      def can_confirm?
        true
      end

      private

      def bill_to_forename
        # bill_name = @user[:name].to_s.split(' ')
        # bill_name.pop if bill_name.length > 1
        # bill_name.join(' ')
        BILL_TO_FORENAME
      end

      def bill_to_surname
        # @user[:name].to_s.split(' ').last
        BILL_TO_SURNAME
      end

      def bill_to_email
        # @user[:email]
        BILL_TO_EMAIL
      end

      def card_expiry_date
        # As the agreement with Visa CYBS, the card_expiry_date will be
        # a future dummy date
        return (Time.now + FUTURE_EXPIRY_MONTHS.to_i.months).strftime('%m-%Y')
      end

      def base_amount
        if transaction_object?
          @object.base_amount
        else
          @object.amount
        end
      end

      def transaction_object?
        @object.is_a? CreditCardBillTransaction
      end

      def validate_token_result(result, signature)
        check_signature(result, signature)
        invalid_fields = result[:invalid_fields].to_s.split(',')[0]
        raise_error(result[:reason_code], invalid_fields)
      end

      def check_signature(result, signature)
        return if Channel::Config::VISA_WIREMOCK.present?
        raise_error if result[:signature].strip != signature.strip
      end

      def raise_error(reason_code = nil, invalid_field = nil)
        case reason_code.to_s
        when RC_ACCEPTED # 100
          return
        when RC_ERROR, RC_DECLINED # 101, 102
          raise ::Exceptions::Visa::InvalidCreditCardNumber.new
        end
        raise ::Exceptions::Visa::GeneralError.new
      end

      def track_id
        @object.respond_to?(:id) ? @object.id : nil
      end

      def hash_sensitive_data(data)
        return unless data.is_a? Hash
        CreditCardBillHelper.hash_cc_number_in_object(data, [:card_number, :card_expiry_date])
        CreditCardBillHelper.hash_cc_number_in_object(data&.[](:paymentInformation)&.[](:customer), [:customerId])
        CreditCardBillHelper.hash_cc_number_in_object(data, [:payment_token])
      end

      def log_and_metric(action:, url:, payload:, result:, duration: nil, response_code: nil, error: nil)
        hash_sensitive_data(payload)
        hash_sensitive_data(result)

        status    = error.nil? ? :success : :error
        tags      = PARTNER_TAG + [action]
        log_entry = { url: url, payload: payload, response: result }
        others    = { duration: duration }

        if error.present?
          log_entry[:cause] = {
            'class' => error.class.to_s,
            'message' => error&.message
          }
          backtrace = error&.backtrace&.slice(0, 10)&.join("\n")
          LogBook.error(log_entry, tags, backtrace, others, track_id: track_id)
        else
          LogBook.info(log_entry, tags, others, track_id: track_id)
        end

        entries = {
          action: action,
          partner: 'visa',
          product: CREDIT_CARD_BILL_PRODUCT,
          status: status,
          response_code: response_code,
          biller_product: @object&.biller&.name
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, entries)
      end

    end
  end
end
