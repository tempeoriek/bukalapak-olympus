module Recurrence
  module Pdam
    class Notifier < Recurrence::Postpaid::Notifier

      MAX_INQUIRY_RETRY = 3.freeze

      def initialize(template, template_detail_id, options={})
        super(template, template_detail_id)
        @operator_id = template_detail.operator_id
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
          operator_name: operator.name,
          customer_number: template_detail.customer_number,
          customer_name: template_detail.customer_name
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
          operator_name: operator.name,
          customer_number: template_detail.customer_number
        }
      end

      def notify_success_transaction_payload
        {
          product_name: postpaid_product,
          customer_name: template_detail.customer_name,
          customer_number: template_detail.customer_number,
          operator_name: operator.name,
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
          operator_name: operator.name,
          action_date: Date.today,
          remote_id: @options[:remote_id],
          invoice_id: @options[:invoice_id],
          amount: @options[:amount]
        }
      end

      def template_detail
        @template_detail ||= PdamRecurrenceTemplateDetail.find(@template_detail_id)
      end

      def operator
        @operator ||= PdamOperator.find(@operator_id)
      end

      def postpaid_product
        'pdam'
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
            body: '2 hari lagi jadwal transaksi rutin Air PDAM. Pastikan saldo BukaDompet kamu cukup, ya.',
            image: nil,
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices",
            tag: 'pdam-recurrent-balance-reminder'
          }
        }
      end

      def get_balance_push_notif_payload(buyer_id)
        {
          user_id: buyer_id,
          headings: 'Transaksi Rutin Sebentar Lagi',
          contents: '2 hari lagi jadwal transaksi rutin Air PDAM. Pastikan saldo BukaDompet kamu cukup, ya.',
          tag: 'pdam-recurrent-balance-reminder',
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices"
        }
      end

      def get_buyer_id
        ::PdamRecurrenceTemplateDetail.find_by(id: @template_detail_id).buyer_id
      end
    end
  end
end
