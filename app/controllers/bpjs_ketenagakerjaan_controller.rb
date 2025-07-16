class BpjsKetenagakerjaanController < PostpaidsController

  PRODUCT_NAME = BPJS_KETENAGAKERJAAN_PRODUCT

  def inquiries
    form = Form::BpjsKetenagakerjaan.new(
      params[:customer_number],
      params[:payment_period],
      buyer_type
    )
    action = Action::PostpaidTransaction::Inquiry.new(form)
    result = action.run!
    render_response(bpjs_ketenagakerjaan_inquiry_format(result), 200)
  end
  
  def create
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0
    form = Form::BpjsKetenagakerjaan.new(
      params[:customer_number],
      params[:payment_period]
    )
    action = Action::BpjsKetenagakerjaanTransaction::Create.new(form, decoded_token[:resource_owner_id], transaction_type)
    transaction = action.run!
    render_response(transaction.as_json({masked: true}), 201)
  end

  def show
    super {
      |id|
        BpjsKetenagakerjaanTransaction.find_by_id(id)
    }
  end

  def get_receipt
    transaction = BpjsKetenagakerjaanTransaction.find_by_id(params[:id])
    raise Exceptions::UnauthorizedUser.new(signed_in: true) unless transaction.buyer_id == decoded_token[:resource_owner_id] || is_role_authorize?(decoded_token[:resource_owner][:role])

    result = Action::PostpaidTransaction::GetReceipt.new(transaction, params[:type]).run!
    if params[:type] == 'pdf'
      send_data result[:pdf], filename: result[:filename], type: 'application/pdf'
    else
      render_response({ page_body: result }, 200)
    end
  end
end
