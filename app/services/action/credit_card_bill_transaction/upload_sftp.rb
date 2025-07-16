module Action
  module CreditCardBillTransaction
    class UploadSftp
      include Postpaid::Constant
      include LoggerUtility

      BNI_SFTP_HOST = ENV['BNI_SFTP_HOST'].freeze # bukalapak host used for bni
      BNI_SFTP_PORT = ENV['BNI_SFTP_PORT'].freeze # bukalapak host used for bni
      BNI_SFTP_DIRECTORY = ENV['BNI_SFTP_DIRECTORY'].freeze
      BNI_SFTP_USERNAME = ENV['BNI_SFTP_USERNAME'].freeze
      BNI_SFTP_PASSWORD = ENV['BNI_SFTP_PASSWORD'].freeze
      BNI_CONFIG = {
        host: BNI_SFTP_HOST,
        port: BNI_SFTP_PORT,
        user: BNI_SFTP_USERNAME,
        password: BNI_SFTP_PASSWORD
      }.freeze

      def initialize(start_date, end_date, filename, biller_type = 'NON_BNI')
        @start_date = start_date
        @end_date = end_date
        @filename = filename
        @biller_type = biller_type
      end

      def run!
        sftp_conn = ::Channel::SftpConnection.new(BNI_CONFIG)

        content = pull_data(@start_date, @end_date)
        destination = "#{BNI_SFTP_DIRECTORY}#{@filename}"

        processed_time = sftp_conn.send_file(content, destination)
        build_response(processed_time, @filename)
      end

      private

      def pull_data(start_date, end_date)
        trxs = ::CreditCardBillTransaction.where(processed_at: start_date..end_date, state: [1,2]).select{|trx| trx.partner.name == BNI}
        if @biller_type == 'BNI'
          trxs = trxs.select{|trx| trx.biller.code == 'BNI'}
        elsif @biller_type == 'NON_BNI'
          trxs = trxs.select{|trx| trx.biller.code != 'BNI'}
        end
        csv_string = '';
        csv_string = trxs.map do |transaction|
          format_string(transaction)
        end.join("\n")

        csv_string.prepend(csv_header + "\n")

        log_event("BNI Reconcile for biller #{@biller_type} with #{trxs.count} transaction's count", %w[bni upload sftp service])

        csv_string
      end

      def format_string(transaction)
        row = [
          masking(transaction.card_number),
          transaction.reference_number.to_s,
          transaction.base_amount,
          transaction.biller.biller_code,
          format_time(transaction.processed_at),
          transaction.partner_financial_journal_number.to_s,
          transaction.response_code
        ]
        row = row + [format_date(transaction.processed_at), format_hour(transaction.processed_at)] if @biller_type == 'BNI'
        row.join(",")
      end

      def build_response(time, filename)
        {
          status: 'delivered',
          filename: filename,
          delivered_time: time.getlocal("+07:00").strftime("%Y%m%d%H%M%S")
        }.to_json
      end

      def format_time(time)
        time.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
      end

      def format_date(time)
        time.in_time_zone.strftime("%Y-%m-%d")
      end

      def format_hour(time)
        time.in_time_zone.strftime("%H:%M:%S")
      end

      def masking(card_number)
        card_number[0..5]+("*"*(card_number.length-10))+card_number[-4..-1]
      end

      def csv_header
        return 'billing_id,reff_num,amount,bank,recharge_time,no journal,respon code,date,hour' if @biller_type == 'BNI'
        'billing_id,reff_num,amount,bank,recharge_time,no journal,respon code'
      end
    end
  end
end
