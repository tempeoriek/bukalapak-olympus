# frozen_string_literal: true

require 'premailer'

module Action
  module PostpaidTransaction
    class EmailNotif
      include ActionView::Context
      include ActionView::Helpers
      include MailerUtility

      attr_accessor :user_id, :user, :transaction
      attr_accessor :total_amount, :uniq_code, :voucher_amount
      attr_accessor :deposit_reduction_amount, :dana_reduction_amount
      attr_accessor :payment_id, :payment_type, :payment_method

      ALLOWED_STATE = Set.new(%w[partner_succeeded partner_failed succeeded failed])

      def initialize(transaction, user_id = nil)
        _prepare_context
        @transaction = transaction
        @user_id = user_id || transaction.buyer_id
      end

      def run!
        return false unless run?
        @user = Escrow::UserDetail.get(user_id)
        return false if user[:email].blank?
        invoice = Escrow::InvoiceDetail.get(transaction.invoice_id)
        set_invoice_vars(invoice)
        status = STATE_MAPPER[transaction.state]
        payload = {
          subject: SUBJECT_MAPPER[status] % PRODUCT_NAME_MAPPER[transaction.product_type],
          tag: EMAIL_TAG_MAPPER[transaction.product_type][status],
          body: get_body(status)
        }
        ::Channel::Notif.send_email(user, payload)
      end

      private

      def run?
        Toggles::EmailNotif.active? && transaction && ALLOWED_STATE.include?(transaction.state)
      end

      def get_body(status)
        product_type = transaction.product_type.underscore
        haml_file = "transaction_#{status}"

        layout_path = File.expand_path(File.join('views/layouts', 'mailer_extended'))
        mail_path = File.expand_path(File.join("views/mailer/#{product_type}", haml_file))

        mail = render(mail_path, self)
        plain_body = render(layout_path, self, mail)

        premailer = Premailer.new(plain_body, :warn_level => Premailer::Warnings::SAFE, :with_html_string => true)
        premailer.to_plain_text
        premailer.to_inline_css.html_safe
      end

      def set_invoice_vars(invoice)
        self.payment_id = invoice[:payment_id]
        self.total_amount = invoice[:amount][:total]
        self.uniq_code = invoice[:amount][:details][:payment].to_i.abs
        self.voucher_amount = invoice[:amount][:details][:voucher].to_i.abs
        self.deposit_reduction_amount = invoice[:amount][:details][:wallet].to_i.abs
        self.dana_reduction_amount = invoice[:amount][:details][:partner_reductions].to_i.abs
        self.payment_type = invoice[:payment_type] == 'wallet' ? 'deposit' : invoice[:payment_type]
        self.payment_method = PAYMENT_METHOD_MAPPER[payment_type.to_sym]
      end
    end
  end
end
