# frozen_string_literal: true

module Action
  module CreditCardBillTransaction
    class SendEmailReconcile 
      include MailerUtility
      include LoggerUtility

      KODE_MITRA = Channel::Config::BNI_KODE_MITRA
      KODE_CABANG = Channel::Config::BNI_KODE_CABANG
      KODE_LOKET = Channel::Config::BNI_KODE_LOKET
      ACCOUNT_NUM = Channel::Config::BNI_ACCOUNT_NUM
      BNI_RECONCILE_EMAILS = ENV['BNI_RECONCILE_EMAILS']&.split(',')

      TRX_TYPE = {
        'BNI' => 41,
        'NON_BNI' => 42,
      }

      def initialize(start_date, end_date, filename)
        @start_date = start_date
        @end_date = end_date
        @filename = filename
      end

      def run!
        content = pull_data(@start_date, @end_date)
        user = {
          email: BNI_RECONCILE_EMAILS,
          user_id: 0,
        }
        
        payload = {
          subject: "Data Reconcile CC Bill BNI - #{@start_date.strftime("%d-%m-%Y")}",
          body: get_body,
          tag: 'bni_reconcile_email',
        }
        options = {
          attachments: [{ content: Base64.strict_encode64(content), name: @filename }]
        }
        
        ::Channel::Notif.send_email(user, payload, options)
        processed_time = Time.now
        build_response(processed_time, @filename)
      end

      def get_body
        haml_file = 'bni_reconcile_email'

        mail_path = File.expand_path(File.join("views/mailer/credit_card_bill", haml_file))

        plain_body = render(mail_path, self)

        premailer = Premailer.new(plain_body, :warn_level => Premailer::Warnings::SAFE, :with_html_string => true)
        premailer.to_plain_text
        premailer.to_inline_css.html_safe
      end

      private

      def pull_data(start_date, end_date)
        trxs = ::CreditCardBillTransaction.where(processed_at: start_date..end_date, state: [1,2]).select{|trx| trx.partner.name == BNI}
        csv_string = '';
        csv_string = trxs.map do |transaction|
          format_string(transaction)
        end.join("\n")

        csv_string.prepend(csv_header + "\n")
        log_event("BNI Reconcile for biller with #{trxs.count} transaction's count", %w[bni email reconcile service])

        csv_string
      end

      def format_string(transaction)
        row = [
          agent_code,
          masking(transaction.card_number),
          ACCOUNT_NUM,
          transaction.reference_number.to_s,
          transaction.base_amount,
          '',
          transaction.biller.code == 'BNI' ? TRX_TYPE['BNI'] : TRX_TYPE['NON_BNI'],
          masking(transaction.card_number),
          format_time(transaction.processed_at),
          transaction.partner_financial_journal_number.to_s,
        ]
        row.join(",")
      end

      def csv_header
        'kode_agent,billing_id,accountNum,reff_num,amount,provider_id,trxtype_id,biller_code,recharge_time,jurnal'
      end

      def agent_code
        KODE_MITRA+KODE_CABANG+KODE_LOKET
      end

      def format_time(time)
        time.in_time_zone.strftime("%d/%m/%Y %H:%M")
      end

      def masking(card_number)
        card_number[0..5]+("*"*(card_number.length-10))+card_number[-4..-1]
      end

      def build_response(time, filename)
        {
          status: 'delivered',
          filename: filename,
          delivered_time: time.getlocal("+07:00").strftime("%Y%m%d%H%M%S")
        }.to_json
      end
    end
  end
end