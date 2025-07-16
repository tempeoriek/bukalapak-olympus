class BpjsKesehatanController < PostpaidsController

  PRODUCT_NAME = BPJS_KESEHATAN_PRODUCT

  def inquiries
    form = Form::BpjsKesehatan.new(
      params[:customer_number],
      params[:payment_period],
      params[:paid_until][:month],
      params[:paid_until][:year],
      buyer_type
    )
    action = Action::PostpaidTransaction::Inquiry.new(form)
    result = action.run!
    render_response(bpjs_kesehatan_inquiry_format(result), 200)
  end

  def create
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0
    form = Form::BpjsKesehatan.new(
      params[:customer_number],
      params[:payment_period],
      params[:paid_until][:month],
      params[:paid_until][:year],
      buyer_type
    )
    phone_number = decoded_token[:resource_owner][:phone] rescue ''
    action = Action::BpjsKesehatanTransaction::Create.new(form, decoded_token[:resource_owner_id], phone_number, transaction_type)
    transaction = action.run!
    render_response(transaction.as_json, 201)
  end

  def show
    super {
      |id|
        BpjsKesehatanTransaction.find_by_id(id)
    }
  end

  def pay
    super {
      |remote_transaction_id|
        BpjsKesehatanTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def invoicing
    super {
      |remote_transaction_id|
        BpjsKesehatanTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def confirm
    super {
      |remote_transaction_id|
        BpjsKesehatanTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def get_receipt
    transaction = BpjsKesehatanTransaction.find_by_id(params[:id])
    raise Exceptions::UnauthorizedUser.new(signed_in: true) unless transaction.buyer_id == decoded_token[:resource_owner_id] || is_role_authorize?(decoded_token[:resource_owner][:role])

    result = Action::PostpaidTransaction::GetReceipt.new(transaction, params[:type]).run!
    if params[:type] == 'pdf'
      send_data result[:pdf], filename: result[:filename], type: 'application/pdf'
    else
      render_response({ page_body: result }, 200)
    end
  end
end
