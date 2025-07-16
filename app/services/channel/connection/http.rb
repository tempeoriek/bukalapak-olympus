require 'rest-client'

module Channel
  module Connection
    module Http

      RestDefault = { open_timeout: ENV['DEFAULT_OPEN_TIMEOUT'].to_i, timeout: ENV['DEFAULT_TIMEOUT'].to_i }

      def self.restclient(opts, &block)
        RestClient::Request.execute(RestDefault.merge(opts), &block)
      end

      def self.get(url, auth, query={}, headers={}, opts={})
        restclient_connection('get', url, auth, {}, query, headers, opts)
      end

      def self.post(url, auth, payload, headers={}, opts={})
        restclient_connection('post', url, auth, payload, {}, headers, opts)
      end

      def self.patch(url, auth, payload)
        restclient_connection('patch', url, auth, payload)
      end

      def self.delete(url, auth, headers={}, opts={})
        restclient_connection('delete', url, auth, {}, {}, headers, opts)
      end

      def self.restclient_connection(http_method, url, auth, payload={}, query={}, headers_opt={}, opts={})
        headers = {
          authorization: auth,
          content_type: :json,
          accept: :json,
          user_agent: 'Bukalapak',
         'BL-Service': 'olympus'
        }.merge(headers_opt)

        opts[:timeout] ||= 60

        headers = headers_opt if opts[:override_headers]
        payload = RestClient::Utils.encode_query_string(payload) if opts[:encode_query_string]

        begin
          case http_method.to_sym
          when :get
            headers[:params] = query
            response = restclient({
              method: http_method.to_sym,
              url: url,
              headers: headers,
              timeout: opts[:timeout],
              open_timeout: opts[:open_timeout] || opts[:timeout]
            })
          when :post, :patch
            payload = payload.to_json if headers[:content_type] == :json
            response = restclient({
              method: http_method.to_sym,
              url: url,
              payload: payload,
              headers: headers,
              timeout: opts[:timeout],
              open_timeout: opts[:open_timeout] || opts[:timeout]
            })
          when :delete
            response = restclient({
              method: http_method.to_sym,
              url: url,
              headers: headers,
              timeout: opts[:timeout],
              open_timeout: opts[:open_timeout] || opts[:timeout]
            })
          else
            raise 'unsupported method'
          end

          payload = hash_cc_number(payload, opts[:crypto_hash_object_keys])

          log_message = {
            http_method: http_method,
            url: opts[:censored_url] || url,
            header: headers,
            payload: payload,
            response: opts[:skip_log_response] || response.to_s.blank? ? nil : JSON.parse(response)
          }
          log_request(['restclient', 'success'], log_message)

          response
        rescue RestClient::Exception => e
          payload = hash_cc_number(payload, opts[:crypto_hash_object_keys])

          log_message = {
            http_method: http_method,
            url: url,
            payload: payload,
            query: query,
            response: {
              message: e.message,
              code: e.response&.code,
              body: e.response&.body
            }
          }

          log_request(['restclient', 'error'], log_message)
          raise e
        end
      end

      def self.log_request(tags, message, track_id = nil)
        body = message.dig(:payload, :data, :body) rescue nil
        if body && body.is_a?(String)
          message[:payload][:data][:body] = message[:payload][:data][:body][1..50]
        end
        log = {
          tags: tags,
          message: message
        }
        log[:track_id] = track_id.to_s unless track_id.nil?
        Logger2.info(log.to_json)
      end

      def self.hash_cc_number(payload, keys)
        return payload if keys.nil?
        obj = payload.is_a?(String) ? JSON.parse(payload) : payload
        CreditCardBillHelper.hash_cc_number_in_object(obj, keys)
        payload.is_a?(String) ? obj.to_json : obj
      end
    end
  end
end
