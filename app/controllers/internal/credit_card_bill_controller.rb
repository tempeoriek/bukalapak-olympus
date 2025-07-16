module Internal
  class CreditCardBillController < Internal::PostpaidController

    PRODUCT_NAME = CREDIT_CARD_BILL_PRODUCT

    def show
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      transaction = CreditCardBillTransaction.find_by(remote_transaction_id: params[:id])
      raise Exceptions::TransactionNotFound.new unless transaction.present?

      render_response(transaction.as_json({internal: true}), 200)
    end

    def create
      #basic authentication
      authenticated = http_basic_authenticate
      raise Exceptions::UnauthorizedUser.new  unless authenticated == true

      service = request_bl_service
      transaction_type = service == 'middleman' ? COLLECTING_AGENT_USER_TRANSACTION_TYPE : NORMAL_USER_TRANSACTION_TYPE
      buyer_type = transaction_type == COLLECTING_AGENT_USER_TRANSACTION_TYPE ? COLLECTING_AGENT_BUYER_TYPE : NORMAL_BUYER_TYPE

      form = Form::CreditCardBill.new(params[:customer_number], params[:biller_id], params[:amount], buyer_type)
      # zeus cc bill only use pnl as partner
      raise Exceptions::CreateTransactionError.new if buyer_type == COLLECTING_AGENT_BUYER_TYPE && form.partner.name.downcase != 'pnl'

      action = Action::CreditCardBillTransaction::Create.new(form, params[:buyer_id], transaction_type)
      transaction = action.run!
      render_response(transaction.as_json, 201)
    end

    def pay
      super {
        |remote_transaction_id|
          CreditCardBillTransaction.find_by(remote_transaction_id: remote_transaction_id)
      }
    end

    def invoicing
      super {
        |remote_transaction_id|
          CreditCardBillTransaction.find_by(remote_transaction_id: remote_transaction_id)
      }
    end

    def confirm
      super {
        |remote_transaction_id|
          CreditCardBillTransaction.find_by(remote_transaction_id: remote_transaction_id)
      }
    end

    def status
      super {
        |id|
          CreditCardBillTransaction.find_by_id(id)
      }
    end

    def pnl_callback
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true
      transaction = Action::CreditCardBillTransaction::PnlCallback.new(params).run!

      render_response(transaction.as_json(internal: true), 200)
    rescue ::Exceptions::InvalidStatusError => e # CHECK: this exception probably will never happen
      render_response({ 'message': 'OK' }, 200)
    end

    def inquiries
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      # only pass cust number and biller_id, less username compared to public version
      form = Form::CreditCardBill.new(params[:customer_number], params[:biller_id])
      if form.partner.name == 'pnl'
        return render_response(credit_card_bill_pnl_inquiry_format(form), 200)
      elsif form.partner.name == 'visa'
        return render_response(credit_card_bill_visa_inquiry_format(form), 200)
      end
      result = Action::PostpaidTransaction::Inquiry.new(form).run!
      render_response(credit_card_bill_inquiry_format(result), 200)
    end
  end
end
