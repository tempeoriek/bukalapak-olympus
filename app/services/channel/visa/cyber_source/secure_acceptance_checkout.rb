# frozen_string_literal: true

module Channel
  module Visa
    module CyberSource
      class SecureAcceptanceCheckout

        TRANSACTION_TYPE = 'create_payment_token'
        SIGNED_FIELD_NAMES = 'access_key,profile_id,transaction_uuid,signed_field_names,unsigned_field_names,signed_date_time,locale,transaction_type,reference_number,amount,currency,payment_method,bill_to_forename,bill_to_surname,bill_to_email,bill_to_phone,bill_to_address_line1,bill_to_address_city,bill_to_address_state,bill_to_address_country,bill_to_address_postal_code'
        UNSIGNED_FIELD_NAMES = 'card_type,card_number,card_expiry_date'

        def initialize(bill_to_forename:,
                       bill_to_surname:,
                       bill_to_email:,
                       card_number:,
                       card_expiry_date:,
                       amount: '0')
          @bill_to_forename = bill_to_forename
          @bill_to_surname = bill_to_surname
          @bill_to_email = bill_to_email
          @card_number = card_number
          @card_expiry_date = card_expiry_date
          @amount = amount
        end

        def tokenize_card
          # This implementation is a Netflix adaptation from this sample code:
          # https://developer.cybersource.com/library/documentation/dev_guides/samples/sa_sop/ruby_sop.zip
          headers = {
            content_type: 'application/x-www-form-urlencoded',
            accept: 'text/html'
          }
          opts = {
            override_headers: true,
            encode_query_string: true,
            skip_log_response: true,
            open_timeout: 5,
            timeout: 5,
          }
          response = Channel::Connection::Http.post(url, nil, payload, headers, opts)
          parse_html_to_json(html: response)
        end

        def url
          Channel::Config::VISA_CYBS_TOKEN_URL
        end

        def payload(refresh_payload: false)
          return @payload if @payload.present? && !refresh_payload
          @current_time = nil if refresh_payload

          token_payload = {
            'access_key'                  => Channel::Config::VISA_CYBS_ACCESS_KEY, # 7cb88fa24ffb30e79e10949ced57a23c
            'profile_id'                  => Channel::Config::VISA_CYBS_SECURE_ACCEPTANCE_PROFILE_ID, # C3396489-5C91-4188-987C-1BB5B9C3C687
            'transaction_uuid'            => random_uuid, # 19b30c701498d5bc688a02246b63a9ce
            'signed_field_names'          => SIGNED_FIELD_NAMES, # access_key,profile_id,transaction_uuid,signed_field_names,unsigned_field_names,signed_date_time,locale,transaction_type,reference_number,amount,currency,payment_method
            'unsigned_field_names'        => UNSIGNED_FIELD_NAMES, # card_type,card_number
            'locale'                      => 'en',
            'transaction_type'            => TRANSACTION_TYPE, # create_payment_token
            'reference_number'            => reference_number, # anything
            'amount'                      => @amount.to_s,
            'currency'                    => 'IDR',
            'payment_method'              => 'card',
            'bill_to_forename'            => @bill_to_forename,
            'bill_to_surname'             => @bill_to_surname,
            'bill_to_email'               => @bill_to_email,
            'bill_to_phone'               => '',
            'bill_to_address_line1'       => '',
            'bill_to_address_city'        => '',
            'bill_to_address_state'       => '',
            'bill_to_address_country'     => '',
            'bill_to_address_postal_code' => '',
            'signed_date_time'            => signed_date_time # 2020-05-27T08:44:57Z
          }
          token_payload['signature']        = signature(payload: token_payload) # nHAMw3d0RtPpCD/EHjJD+IUbnSwRMgglVpOTEV5Bj+M=
          token_payload['card_type']        = '001' # 001 = visa
          token_payload['card_number']      = @card_number # 4111111111111111
          token_payload['card_expiry_date'] = @card_expiry_date # 01-2025
          @payload = token_payload
        end

        def signature(payload:)
          fields_query = signed_field_names_query(hash_obj: payload)
          key = CreditCardBillHelper.sha256_digest(Channel::Config::VISA_CYBS_SECRET_KEY)
          CreditCardBillHelper.hmac_sha256_digest(fields_query, key)
        end

        private

        def random_uuid
          RbNaCl::Random.random_bytes(16).unpack('H*').first
        end

        def current_time
          @current_time ||= Time.now
        end

        def reference_number
          date = Time.now.in_time_zone.strftime("%Y%m%d%H%M%S%5N")
          "#{date}#{Random.rand(10)}"
        end

        def signed_date_time
          current_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
        end

        def parse_html_to_json(html:)
          parsed_doc = Nokogiri.parse(html)
          inputs = parsed_doc.search('input[type=hidden]')
          data = inputs.reduce({}) { |data, node| data[node["name"].to_sym] = node["value"]; data }
        end

        def signed_field_names_query(hash_obj:)
          signed_field_names = hash_obj['signed_field_names'].split(',')
          fields_query = signed_field_names.map { |field| field + '=' + hash_obj[field.to_s].to_s }.join(',')
        end
      end
    end
  end
end
