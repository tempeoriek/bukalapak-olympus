module Recurrence
  module Postpaid
    class EmailNotif
      include ActionView::Context
      include ActionView::Helpers
      include MailerUtility

      def initialize(template, user_id, payload)
        _prepare_context

        @template = template.sub('olympus_recurrence_', '').split("_").first(2).join("_")
        @user_id = user_id
        @payload = payload.with_indifferent_access
      end

      def run!
        @user = Escrow::UserDetail.get(@user_id)
        return false if @user[:email].blank?

        prepare_variables

        payload = {
          subject: email_subject,
          tag: email_tag,
          body: email_body
        }
        ::Channel::Notif.send_email(@user, payload)
      end

      private

      def prepare_variables
        @amount           = @payload[:amount].to_i
        @product_name     = RECURRENCE_EMAIL_PRODUCT_NAME_MAPPER[@payload[:product_name]]
        @customer_number  = @payload[:customer_number]
        @customer_name    = @payload[:customer_name]
        @power            = @payload[:power]
        @segmentation     = @payload[:segmentation]
        @area             = @payload[:operator_name]

        if @payload[:action_date].present?
          @formatted_date = DateTime.strptime(@payload[:action_date].to_s, "%Y-%m-%d")
        end

        if @payload[:invoice_id].present?
          invoice = Escrow::InvoiceDetail.get(@payload[:invoice_id])
          @payment_id = invoice[:payment_id]
        end
      end

      def email_subject
        RECURRENCE_EMAIL_SUBJECT_MAPPER[@template.to_sym] % [@product_name, I18n.l(@formatted_date, format: "%B %Y"), @payment_id]
      end

      def email_tag
        "#{@product_name}_recurrence_#{@template}"
      end

      def email_body
        email_template = @template
        layout_path = File.expand_path(File.join('views/layouts', 'mailer_virtual'))
        mail_path = File.expand_path(File.join("views/mailer/recurrence", email_template))

        mail = render(mail_path, self)
        plain_body = render(layout_path, self, mail)

        premailer = Premailer.new(plain_body, :warn_level => Premailer::Warnings::SAFE, :with_html_string => true)
        premailer.to_plain_text
        premailer.to_inline_css.html_safe
      end
    end
  end
end
