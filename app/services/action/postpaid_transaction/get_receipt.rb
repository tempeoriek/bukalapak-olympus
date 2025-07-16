# frozen_string_literal: true
# require 'premailer'
module Action
  module PostpaidTransaction
    class GetReceipt
      include MailerUtility

      ALLOWED_STATE = Set.new(%w[partner_succeeded succeeded])

      def initialize(transaction, type)
        @transaction = transaction
        @type = type
      end

      def run!
        raise Exceptions::InvalidStatusError.new('Struk pembelian tidak dapat diproses sebelum transaksi berhasil') unless ALLOWED_STATE.include?(@transaction.state)

        invoice = Escrow::InvoiceDetail.get(@transaction.invoice_id)
        invoice = set_additional_vars(invoice, @transaction)
        build_receipt(invoice)
      end

      def build_receipt(invoice)
        product_type = @transaction.product_type.underscore
        ac = ActionController::Base.new
        body = ac.render_to_string(page_size: 'A4', template: "receipts/#{product_type}.html.haml", layout: 'vp_p2p.html.haml', locals: {:@transaction => @transaction, :@invoice => invoice, util: self, transaction_details_label: TRANSACTION_DETAILS_LABEL})
        case @type
        when 'pdf'
          result = WickedPdf.new.pdf_from_string(
            body,
            margin: { top: 35, left: 0, bottom: 35, right: 0 },
            footer: { content: ac.render_to_string(page_size: 'A4', template: "receipts/footer.html.haml", layout: 'vp_p2p.html.haml') }
          )

          return {
            pdf: result,
            filename: "BUKTI_BAYAR_#{invoice[:payment_id]}.pdf"
          }
        when 'png', 'jpg'
          kit = IMGKit.new(
            body, quality: 60, width: 550
          )
          image = kit.to_img(:png)
          base64_png = Base64.strict_encode64(image)
          return "data:image/png;base64,#{base64_png}"
        else
          raise Exceptions::UnsupportedType.new
        end
      end

      def set_additional_vars(invoice, transaction)
        invoice[:uniq_code] = invoice[:amount][:details][:payment].to_i.abs
        invoice[:amount][:details][:others] = calculate_others_amount(invoice, transaction)

        # for electricity postpaid
        if transaction.try(:unpaid_bill).to_i > 0
          invoice[:closure] = "Anda masih memiliki sisa tunggakan #{transaction.unpaid_bill} bulan"
        else
          invoice[:closure] = 'Terima Kasih'
        end

        invoice
      end

      def calculate_others_amount(invoice, transaction)
        subtotal_amount = invoice.dig(:amount, :details, :transactions).to_i
        transaction_amount = transaction.amount

        subtotal_amount - transaction_amount
      end
    end
  end
end
