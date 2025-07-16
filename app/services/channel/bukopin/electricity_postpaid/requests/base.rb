module Channel
  module Bukopin
    class ElectricityPostpaid
      module Requests
        class Base
          include Constants
          include PostpaidTransactionUtility
          include CachePartnerResponseUtility

          def initialize(buyer_type)
            @buyer_type = buyer_type
          end

          # TODO: Move this as Network's static network instead
          def sign_on
            response = request_network(NetworkCodes::SIGN_ON)
          end

          def sign_off
            response = request_network(NetworkCodes::SIGN_OFF)
          end

          def echo
            response = request_network(NetworkCodes::ECHO_TEST)
          end

          def get_key
            response = request_network(NetworkCodes::GET_KEY)
            bukopin_key = encrypt_key(response[48]).unpack('H*')[0]
            Keystore.set(get_config[:encrypt_key], bukopin_key, 3600)
            bukopin_key
          end

          def flush_key
            Keystore.del(get_config[:encrypt_key])
          end

          private

          def build_request_message
            raise 'Please override this method!'
          end

          def my_parser
            raise 'Please override this method!'
          end

          def initialize_my_tags
            self.class.name.split('::').map { |s| s.underscore }
          end

          def get_config
            if Toggles::BukopinMitraAuth.active? && [AGENT_BUYER_TYPE, BUKA_PENGADAAN_BUYER_TYPE].include?(@buyer_type)
              Channel::Bukopin::ElectricityPostpaid::Constants::AGENT_USER
            else
              Channel::Bukopin::ElectricityPostpaid::Constants::NORMAL_USER
            end
          end

          def retry_exception(exception)
            case exception
            when Exceptions::Bukopin::Unauthorized
              sign_on
            when Exceptions::Bukopin::InvalidSecurityData
              Keystore.expire(get_config[:encrypt_key])
            end
          end

          EXCEPTION_RETRY_LIST = [
            Exceptions::Bukopin::Unauthorized,
            Exceptions::Bukopin::InvalidSecurityData
          ]

          def partner_name
            initialize_my_tags.second
          end

          # Prerequisites: `build_request_message` and `my_parser`
          def wrap_request(track_id: nil, read_timeout: DEFAULT_TIMEOUT, max_retry_count: 3, log_excluding_keys: [], buyer_type: nil)
            request_start_time = ::Time.now

            @log_entry = {}
            @log_entry[:tags] = @tags = initialize_my_tags
            response = nil

            retry_count = 0
            begin
              @log_entry[:track_id] = track_id if track_id.present?

              @payload_object = build_request_message
              payload_raw_message = @payload_object.encode
              @log_entry[:raw_payload] = payload_raw_message[2..-1]
              @log_entry[:raw_response] = raw_response = Connection::Iso8583.send(
                get_config[:host],
                get_config[:port],
                payload_raw_message,
                read_timeout: read_timeout
              )

              response = IsoMessage.decode(raw_response)

              raise Exceptions::Bukopin::Unauthorized if response.need_sign_on?
              raise Exceptions::Bukopin::InvalidSecurityData if response.invalid_security_data?

              response_hash = @log_entry[:response] = block_given? ? yield(response) : response.build_hash(my_parser)
              @log_entry[:message] = 'Request Successful'

              status = :success
            rescue => e
              if EXCEPTION_RETRY_LIST.include?(e.class) && retry_count < max_retry_count
                retry_count += 1
                retry_exception(e.class)
                Logger2.warn(@log_entry.merge(message: "Retrying because [#{e}] with RC [#{response[39]}]", raw_response: raw_response))
                retry
              else
                status = :error
                @error = e
                @log_entry[:message] = "Request Failed with Error [#{@error}]"
                raise e
              end
            ensure
              ## Cache Partner Response
              action = @tags.last.underscore
              action = 'create' if action.eql?('payment') ## It is tranformed because sepulsa used `create` instead of `payment`
              reference_id = @customer_number || @track_id
              response_code = response.present? ? response[39] : "unknown_response"
              if %w[inquiry create].include? action
                cache_partner_response(ELECTRICITY_PRODUCT, action, partner_name, reference_id, response_code)
              end

              ## Metric
              duration = ::Time.now - request_start_time
              entry = {
                action: action,
                partner: Postpaid::Constant::BUKOPIN,
                product: @tags.third.underscore,
                biller_product: nil, #nil, as electricity postpaid doesnt have biller_product
                status: status,
                response_code: response ? response[39] : :timeout
              }
              Observer.histogram(Observer::Metric::PARTNER, duration, entry)

              ## Log
              @log_entry[:tags] << status
              @log_entry[:tags] << "retry_#{retry_count}" if retry_count > 0

              @log_entry[:message] += " with RC [#{response[39]}]" if response.present?
              @log_entry[:message] += " with message [#{response_hash[:message]}]" if response_hash.present? && response_hash[:message].present?

              # exclude log keys if any
              log_excluding_keys.each { |key| @log_entry.delete(key) }
              status == :success ? Logger2.info(@log_entry) : Logger2.error(@log_entry)
            end

            response_hash
          end

          def request_network(action_code)
            Network.new(action_code, @buyer_type).run!
          end

          def encrypt_key(get_key_48)
            key =  get_config[:private_key].to_byte_string
            bukopin_key = get_key_48.to_byte_string
            des3 = OpenSSL::Cipher.new('DES-EDE3').decrypt
            des3.padding = 0
            des3.key = key
            encrypted_key = des3.update(bukopin_key)
            encrypted_key << des3.final
          end

          def get_token(stan_number)
            stan = stan_number.to_s.rjust(12, '0')
            trace_id = stan.ljust(16, 'F').to_byte_string

            encrypted_key = Keystore.get(get_config[:encrypt_key]) || begin
              Keystore.find_or_initialize_by(key: get_config[:encrypt_key]).with_lock do
                # Keystore.get is done again inside lock to prevent racing condition
                # won't go to `get_key` if BUKOPIN_ENCRYPT_KEY is set already on other thread
                Keystore.get(get_config[:encrypt_key]) || get_key
              end
            end

            key = encrypted_key.to_byte_string
            des3 = OpenSSL::Cipher.new('DES-EDE3').encrypt
            des3.padding = 0
            des3.key = key
            token_trx = des3.update(trace_id)
            token_trx << des3.final
            token_trx.unpack('H*')[0]
          end

          def failed_response(response_code)
            {
              status: 'failed',
              response_code: response_code,
              message: response_code_message(response_code)
            }
          end

        end
      end
    end
  end
end
