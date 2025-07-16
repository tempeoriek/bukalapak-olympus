# frozen_string_literal: true

module Channel
  module Dji
    class Base
      include PostpaidTransactionUtility
      include ApplicationHelper
      include CachePartnerResponseUtility
      include Action::PostpaidTransaction::Autoswitch

      DEFAULT_OPTIONS = {
        header_length: 2
      }

      PARTNER_NAME = 'dji'
      SECURITY_NUMBER_KEY = 'dji:security_number'
      RC_SUCCESS = '00'
      RC_LOGIN_SESSION_EXPIRED = '34'
      RCS_PENDING_TRANSACTION = Set.new(['01', '03', '04', '05', '10', '14', '19', '38', '39', '67', '71'])
      RCS_FAIL_REQUEST = Set.new(['71', '60', '62', '64', '65', '68', '69', '78', '79', '80', '83', '85'])
      RCS_PARTNER_FAIL_REQUEST = [
        '01', # Error Tidak Terdefinisi
        '02', # Format Message Salah, Silahkan Ulangi Transaksi Kembali
        '03', # Transaksi Anda Tidak Diresponse, Silahkan Coba Beberapa Saat Kemudian
        '04', # No Response From Biller
        '05', # No Response From Host
        '10', # Saat Ini Transaksi Tidak Dapat Dilakukan, Silahkan Coba Beberapa Saat Kemudian
        '12', # Saldo Anda Tidak Mencukupi
        '14', # Sedang Terjadi Kendala Pada Media Penyimpanan
        '15', # Produk Tidak Dikenal
        '17', # Transaksi Gagal
        '18', # Switching Hulu Belum Diregistrasi
        '19', # Data Tidak Ditemukan
        '27', # Saat Ini Transaksi Tidak Dapat Dilakukan, Silahkan Coba Beberapa Saat Kemudian..
        '34', # Periode Login Anda Sudah Berakhir,silahkan Login Ulang
        '37', # Terjadi Kesalahan Saat Setting Admin Bank
        '38', # Link Ke Biller Terputus
        '39', # Time Out From Biller
        '40', # Jenis Message Tidak Dikenal
        '41', # Anda Tidak Diperbolehkan Bertransaksi Produk Ini
        '42', # Harga Jual Tidak Valid
        '46', # Transaksi Sudah Kadaluwarsa
        '67', # Terjadi Kegagalan Saat Proses Transaksi
        '73', # Terjadi Kegagalan Saat Mengarahkan Transaksi
        '85', # Sedang Dalam Masa Cut Off, Silahkan Coba Beberapa Saat Kemudian
      ]

      INQUIRY_NUMBER_OF_RETRY = 2
      INQUIRY_DEFAULT_READ_TIMEOUT = 10
      CREATE_DEFAULT_READ_TIMEOUT = 60

      ## Parsers
      # key   => attribute name
      # value => attribute length
      BIT_48_ATTR = {
        product_code: 6,
        reserved: 1,
        customer_number: 20,
        bill_length: 2,
        date_server: 8,
        time_server: 6,
        customer_name: 30,
        amount: 12,
        admin_fee: 12,
        reference: 64,
        switch_id: 10
      }.freeze

      CIRCUITBOX_CONFIGURATION = {
        exceptions: [Exceptions::SocketConnectionTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT],
        sleep_window: 60,
        time_window: 30,
        volume_threshold: 10,
        error_threshold: 50
      }.freeze

      def inquiry(payload, options = {})
        retry_when_timeout = !!options[:retry_when_timeout]

        wrap_request(action: 'inquiry', num_of_retry: INQUIRY_NUMBER_OF_RETRY, retry_when_timeout: retry_when_timeout) do
          @options[:read_timeout] = options[:read_timeout].nil? ? INQUIRY_DEFAULT_READ_TIMEOUT : options[:read_timeout]
          @message = build_inquiry_message(payload)

          if Toggles::DjiCircuitBreaker.active?
            response = ::CircuitBreaker.run(:dji_inquiry, CIRCUITBOX_CONFIGURATION) do
              Channel::Connection::Iso8583.send(host, port, @message, @options)
            end
          else
            response = Channel::Connection::Iso8583.send(host, port, @message, @options)
          end

          @decoded_response = Iso8583::Dji.decode(response)
          unless @decoded_response[39] == RC_SUCCESS
            autoswitch_options = {}
            autoswitch_options[:operator_id] = @object.operator.id if @product_type == ::Postpaid::Constant::PDAM_PRODUCT
            record_autoswitch_value(
              'inquiry',
              autoswitch_status(@decoded_response[39]),
              @product_type,
              autoswitch_options
            )

            raise_error(@decoded_response[39]) 
          end
        end
      end

      def create(inquiry_data, amount)
        wrap_request(action: 'create_transaction') do
          @options[:read_timeout] = CREATE_DEFAULT_READ_TIMEOUT
          @message = build_payment_message(inquiry_data, amount)
          ## Save partner transaction id to database
          @object.update!(partner_transaction_id: inquiry_data[37].to_s)

          response = Channel::Connection::Iso8583.send(host, port, @message, @options)
          @decoded_response = Iso8583::Dji.decode(response)

          raise ::Exceptions::SignOnFailed if @decoded_response[39] == RC_LOGIN_SESSION_EXPIRED
        end
      end

      def get_transaction_by_id
        wrap_request(action: 'confirm') do
          payload = {
            customer_number: @object.customer_number,
            product_code: @product_code,
            partner_transaction_id: @object.partner_transaction_id,
            transaction_date: @object.processed_at&.strftime("%d%m%Y")
          }
          @message = build_check_message(payload)
          response = Channel::Connection::Iso8583.send(host, port, @message, @options)
          @decoded_response = Iso8583::Dji.decode(response)

          raise ::Exceptions::SignOnFailed if @decoded_response[39] == RC_LOGIN_SESSION_EXPIRED
        end
      rescue => e
        raise ::Exceptions::PartnerTransactionNotFound.new
      end

      def can_confirm?
        true
      end

      private

      def wrap_request(action: 'DEFAULT', num_of_retry: 1, retry_when_timeout: false)
        retries ||= 0
        start_time = ::Time.current

        yield

        @decoded_response
      rescue ::Exceptions::SignOnFailed
        raise unless (retries += 1) <= num_of_retry
        sign_on_network
        retry
      rescue Exceptions::SocketConnectionTimeout, Errno::ETIMEDOUT => e
        autoswitch_options = {}
        autoswitch_options[:operator_id] = @object.operator.id if @product_type == ::Postpaid::Constant::PDAM_PRODUCT

        if retry_when_timeout && ((retries += 1) <= num_of_retry)
          record_autoswitch_value('inquiry', :failed, @product_type, autoswitch_options) if action == 'inquiry'

          tags = get_my_tags(action, :timeout, retries)
          logs = log_message(url, @message, to_hash_log(@decoded_response), e)
          log_request(tags, logs)
          retry
        end

        record_autoswitch_value('inquiry', :failed, @product_type, autoswitch_options) if action == 'inquiry'
        status = :timeout
        error = e
        raise Exceptions::Dji::ErrTimeout.new if e.class == Errno::ETIMEDOUT

        raise
      rescue Errno::EHOSTUNREACH
        raise Exceptions::Dji::HostUnreachableError
      ensure
        ## Publish Metric
        duration        = ::Time.current - start_time
        status        ||= @decoded_response&.[](39).present? ? transform_response_code(@decoded_response[39]) : :error
        response_code   = @decoded_response&.[](39).present? ? @decoded_response[39].to_s : :null # use `null` to make explicit rc is not returned
        entries = {
          action: action,
          partner: PARTNER_NAME,
          product: @product_type,
          biller_product: @biller_product,
          status: status,
          response_code: response_code
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, entries)

        ## Publish Log
        error ||= nil
        tags = get_my_tags(action, status, retries)
        logs = log_message(url, @message, to_hash_log(@decoded_response), error)
        log_request(tags, logs)

        ## Cache Response Code
        action = 'create' if action.eql?('create_transaction') ## standard action naming for create transaction

        if %w[create].include? action
          cache_partner_response(@product_type, action, PARTNER_NAME, @object.remote_transaction_id, response_code)
        end
      end

      # only use network SIGN ON
      def sign_on_network
        message = build_network_message

        response = Channel::Connection::Iso8583.send(host, port, message, @options)

        decoded_response = Iso8583::Dji.decode(response) # only to save security number

        tags = get_my_tags(:sign_on, :success)
        logs = log_message(url, message, to_hash_log(decoded_response))
        log_request(tags, logs)

        set_cache_network(decoded_response[61])

        decoded_response[61]
      end

      def build_inquiry_message(payload, &block)
        message = Iso8583::Dji.new(DJI_INQUIRY_MTI)

        message[3] = 380000
        message[4] = 0
        message[18] = 9001
        message[37] = increment_unique_number
        message[48] = payload
        message[61] = security_number

        # process message further if needed
        yield(message) if block_given?

        message.encode
      end

      def build_payment_message(inquiry_data, amount, &block)
        message = Iso8583::Dji.new(DJI_PAYMENT_MTI)

        message[3] = 180000
        message[4]  = amount
        message[11] = inquiry_data[11]
        message[18] = inquiry_data[18]
        message[32] = inquiry_data[32]
        message[37] = inquiry_data[37]
        message[41] = inquiry_data[41]
        message[42] = inquiry_data[42]
        message[43] = DJI_CARD_ACCEPTOR_NAME
        message[48] = inquiry_data[48].ljust(171) # To handle incomplete message from partner
        message[61] = security_number

        # process message further if needed
        yield(message) if block_given?

        message.encode
      end

      def build_check_message(payload, &block)
        check_payload = ''
        check_payload += payload[:product_code].ljust(6)
        check_payload += '0'
        check_payload += payload[:customer_number].ljust(20)
        check_payload += '00'
        check_payload += payload[:transaction_date]
        check_payload += '000000'
        check_payload += ' '.ljust(30)
        check_payload += '000000000000'
        check_payload += '000000000000'
        check_payload += ' '.ljust(64)
        check_payload += '0000000000'

        message = Iso8583::Dji.new(DJI_CHECK_MTI)
        message[3] = 170000
        message[4]  = 0
        message[18] = 9001
        message[37] = payload[:partner_transaction_id]
        message[48] = check_payload
        message[61] = security_number

        # process message further if needed
        yield(message) if block_given?

        message.encode
      end

      def build_network_message
        message = Iso8583::Dji.new(DJI_NETWORK_MTI)
        message[70] = '001'
        message.encode
      end

      def transform_response_code(response_code)
        return :success if RC_SUCCESS == response_code
        return :fail    if RCS_FAIL_REQUEST.include? response_code
        return :error
      end

      def transaction_status(response_code)
        return 'success' if response_code == '00'
        return 'pending' if RCS_PENDING_TRANSACTION.include? response_code
        return 'failed'
      end

      def autoswitch_status(response_code)
        return :failed if RCS_PARTNER_FAIL_REQUEST.include? response_code
        return :success
      end

      def raise_error(response_code)
        case response_code
        when '65', '19'
          raise ::Exceptions::UnregisteredNumber.new
        when '80', '62', '64', '74'
          raise ::Exceptions::BillAlreadyPaid.new
        when '03', '04', '05', '10', '14', '27', '38', '39', '67', '71'
          raise ::Exceptions::TransactionCannotBeDone.new
        when '34'
          raise ::Exceptions::SignOnFailed.new
        else
          raise ::Exceptions::DefaultError.new
        end
      end

      def parse_bit_48(message)
        result = {}

        offset = 0
        BIT_48_ATTR.each do |attribute, length|
          # even when message length is less than expected, it still can be handled safely
          result[attribute] = message[offset..offset+length-1]
          offset += length
        end
        result
      end

      def host
        self.class::HOST
      end

      def port
        self.class::PORT
      end

      def url
        "#{host}:#{port}"
      end

      def security_number
        security_number = Keystore.get(SECURITY_NUMBER_KEY)
        security_number = sign_on_network if security_number.blank?
        security_number
      end

      def set_cache_network(security_number)
        end_of_day_seconds_remaining = Time.zone.now.end_of_day - Time.zone.now
        Keystore.set(SECURITY_NUMBER_KEY, security_number, end_of_day_seconds_remaining)
      end

      def get_my_tags(action, status, retries = 0)
        tags = %W[#{@product_type} partner dji #{action} #{status}]
        tags.append "retry_#{retries}" if retries.present? && retries > 0
        tags
      end

      def log_message(url, payload, response, error = nil)
        {
          url: url,
          payload: payload,
          response: response
        }.to_s
      end

      def increment_unique_number
        Keystore.increment(self.class::REFERENCE_NUMBER_KEY)
      end

      def to_hash_log(message)
        return nil unless message.present?
        hash = message.to_hash
        hash[:"048"] = parse_bit_48(message[48]) if message[48].present?
        hash
      end
    end
  end
end
