module Recurrence
  module BpjsKesehatan
    class Notifier < Recurrence::Postpaid::Notifier

      MAX_INQUIRY_RETRY = 3.freeze

      def initialize(template, template_detail_id, options={})
        super(template, template_detail_id)
        @options = options
      end

      def run!
        super
      end

      private

      def notify_balance_payload
        {
          product_name: postpaid_product,
          action_date: @options[:action_date],
          customer_number: template_detail.customer_number
        }
      end

      def notify_stop_payload
        {
          product_name: postpaid_product,
          action_date: Date.today,
          customer_number: template_detail.customer_number
        }
      end

      def notify_success_subscribe_payload
        {
          product_name: postpaid_product,
          action_date: @options[:action_date],
          customer_number: template_detail.customer_number
        }
      end

      def notify_success_transaction_payload
        {
          product_name: postpaid_product,
          customer_name: template_detail.customer_name,
          customer_number: template_detail.customer_number,
          action_date: Date.today,
          remote_id: @options[:remote_id],
          invoice_id: @options[:invoice_id],
          amount: @options[:amount]
        }
      end

      def notify_error_transaction_payload
        {
          product_name: postpaid_product,
          customer_name: template_detail.customer_name,
          customer_number: template_detail.customer_number,
          action_date: Date.today,
          remote_id: @options[:remote_id],
          invoice_id: @options[:invoice_id],
          amount: @options[:amount]
        }
      end

      def template_detail
        @template_detail ||= BpjsKesehatanRecurrenceTemplateDetail.find(@template_detail_id)
      end

      def postpaid_product
        'bpjs_kesehatan'
      end

      def generate_log_message
        {
          buyer_id: template_detail.buyer_id,
          template_detail_id: template_detail.id,
          customer_number: template_detail.customer_number
        }
      end

      def get_balance_onsite_notif_payload(buyer_id)
        {
          user_id: buyer_id,
          body: {
            title: 'Transaksi Rutin Sebentar Lagi',
            body: '2 hari lagi jadwal transaksi rutin BPJS Kesehatan. Pastikan saldo BukaDompet kamu cukup, ya.',
            image: nil,
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices",
            tag: 'bpjs-recurrent-balance-reminder'
          }
        }
      end

      def get_balance_push_notif_payload(buyer_id)
        {
          user_id: buyer_id,
          headings: 'Transaksi Rutin Sebentar Lagi',
          contents: '2 hari lagi jadwal transaksi rutin BPJS Kesehatan. Pastikan saldo BukaDompet kamu cukup, ya.',
          tag: 'bpjs-recurrent-balance-reminder',
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices"
        }
      end

      def get_buyer_id
        ::BpjsKesehatanRecurrenceTemplateDetail.find_by(id: @template_detail_id).buyer_id
      end
    end
  end
end
