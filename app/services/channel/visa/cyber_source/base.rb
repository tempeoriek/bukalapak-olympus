# frozen_string_literal: true

module Channel
  module Visa
    module CyberSource
      class Base

        PATH = nil
        HTTP_METHOD = nil
        PROFILE_ID = nil

        def url
          "#{api_protocol}://#{Channel::Config::VISA_CYBS_API_HOST}/#{self.class::PATH}"
        end

        def path
          self.class::PATH
        end

        def payload
          nil
        end

        def send_request(timeout: 10, censored_url: nil, custom_http_headers: {})
          headers = get_headers(custom_http_headers: custom_http_headers)
          opts = {
            override_headers: true,
            timeout: timeout,
            open_timeout: timeout,
            censored_url: censored_url,
          }

          case self.class::HTTP_METHOD
          when :get
            Channel::Connection::Http.get(url, nil, nil, headers, opts)
          when :post
            payload_string = payload.is_a?(Hash) ? payload.to_json : payload
            Channel::Connection::Http.post(url, nil, payload_string, headers, opts)
          when :delete
            Channel::Connection::Http.delete(url, nil, headers, opts)
          end
        end

        private

        def api_protocol
          Channel::Config::VISA_WIREMOCK.present? ? 'http' : 'https'
        end

        def gmt_date_time
          @gmt_date_time ||= DateTime.now.httpdate
        end

        def get_headers(custom_http_headers: {})
          signature = get_signature
          http_headers = {
            'Accept'          => 'application/hal+json;charset=utf-8',
            'Content-Type'    => 'application/json;charset=utf-8',
            'User-Agent'      => 'Bukalapak',
            # 'v-c-client-id'   => Channel::Config::VISA_CYBS_MERCHANT_ID,
            'v-c-merchant-id' => Channel::Config::VISA_CYBS_MERCHANT_ID,
            'Date'            => gmt_date_time,
            'Host'            => Channel::Config::VISA_CYBS_API_HOST.split('/')[0],
            'Signature'       => signature # "keyid=\"48404ad9-efb7-419b-b841-8f7a01b547e7\", algorithm=\"HmacSHA256\", headers=\"host date (request-target) digest v-c-merchant-id\", signature=\"kdMC8qH7KdKc6HMxDbu3ahWKdnEazYqPlYvUj43p0sE=\""
          }.merge(custom_http_headers)
          http_headers['Digest'] = payload_sha256_digest if has_payload? # "SHA-256=PSJhX2peBu/Zj362zvXHhPji+hnB71/gy0EfxTdypDI="
          http_headers['profile-id'] = self.class::PROFILE_ID if self.class::PROFILE_ID.present? # C3396489-5C91-4188-987C-1BB5B9C3C687
          http_headers
        end

        def has_payload?
          [:post, :patch, :put].include? self.class::HTTP_METHOD
        end

        def get_signature
          signature = generate_signature_parameter
          digest = has_payload? ? 'digest ' : ''
          [
            'keyid="' + Channel::Config::VISA_CYBS_API_KEY + '"',
            'algorithm="HmacSHA256"',
            'headers="host date (request-target) ' + digest + 'v-c-merchant-id"',
            'signature="' + signature + '"'
          ].join(', ')
        end

        def payload_sha256_digest
          return @payload_sha256_digest if @payload_sha256_digest
          digest = Base64.strict_encode64(CreditCardBillHelper.sha256_digest(payload.to_json))
          @payload_sha256_digest = "SHA-256=#{digest}"
        end

        def generate_signature_parameter
          signature_string = [
            "host: #{Channel::Config::VISA_CYBS_API_HOST}", # apitest.cybersource.com
            "date: #{gmt_date_time}", # Sat, 30 May 2020 17:48:35 GMT
            "(request-target): #{self.class::HTTP_METHOD.to_s.downcase} /#{path}" #/pts/v2/payouts
          ]
          signature_string << "digest: #{payload_sha256_digest}" if has_payload? # PSJhX2peBu/Zj362zvXHhPji+hnB71/gy0EfxTdypDI=
          signature_string << "v-c-merchant-id: #{Channel::Config::VISA_CYBS_MERCHANT_ID}" # bukalapak_com

          signature_string = signature_string.join("\n").force_encoding(Encoding::UTF_8)
          key = Base64.decode64(Channel::Config::VISA_CYBS_API_SHARED_SECRET_KEY)
          CreditCardBillHelper.hmac_sha256_digest(signature_string, key)
        end

      end
    end
  end
end
