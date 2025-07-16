class ElectricityPostpaidsController < PostpaidsController

  PRODUCT_NAME = ELECTRICITY_PRODUCT

  def inquiries
    ## Validate customer_number
    raise ::Exceptions::InvalidParameterError.new("ID Pelanggan tidak boleh kosong") unless params[:customer_number]
    digits_required = 12
    raise ::Exceptions::InvalidParameterError.new("ID Pelanggan maks. #{digits_required} digit") unless params[:customer_number].length == digits_required

    form = Form::ElectricityPostpaid.new(params[:customer_number], decoded_token&.dig('resource_owner', 'username'), params[:partner], buyer_type)
    raise Exceptions::PartnerNotFound.new('Maaf, lagi ada gangguan. Coba sebentar lagi ya.') unless form.partner_object

    action = Action::PostpaidTransaction::Inquiry.new(form)
    result = action.run!
    render_response(electricity_inquiry_format(result), 200)
  end

  def create
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0
    form = Form::ElectricityPostpaid.new(params[:customer_number], decoded_token&.dig('resource_owner', 'username'), params[:partner], buyer_type, params[:mass_bill_id])
    raise Exceptions::PartnerNotFound.new('Maaf, transaksinya belum berhasil dibuat. Coba sebentar lagi ya.') unless form.partner_object

    action = Action::ElectricityTransaction::Create.new(form, decoded_token[:resource_owner_id], transaction_type, request_context)
    transaction = action.run!
    render_response(transaction.as_json, 201)
  end

  def show
    super {
      |id|
        PostpaidTransaction.find_by_id(id)
    }
  end

  def pay
    super {
      |remote_transaction_id|
        PostpaidTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def invoicing
    super {
      |remote_transaction_id|
        PostpaidTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def confirm
    super {
      |remote_transaction_id|
        PostpaidTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def get_receipt
    transaction = PostpaidTransaction.find_by_id(params[:id])
    raise Exceptions::UnauthorizedUser.new(signed_in: true) unless transaction.buyer_id == decoded_token[:resource_owner_id] || is_role_authorize?(decoded_token[:resource_owner][:role])

    result = Action::PostpaidTransaction::GetReceipt.new(transaction, params[:type]).run!
    if params[:type] == 'pdf'
      send_data result[:pdf], filename: result[:filename], type: 'application/pdf'
    else
      render_response({ page_body: result }, 200)
    end
  end

  def has_transacted
    raise Exceptions::UnauthorizedUser.new unless decoded_token.present?
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0

    super {
      PostpaidTransaction.find_by(buyer_id: decoded_token[:resource_owner_id])
    }
  end
end
