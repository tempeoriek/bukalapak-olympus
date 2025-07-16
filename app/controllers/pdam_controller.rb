class PdamController < PostpaidsController

  PRODUCT_NAME = PDAM_PRODUCT

  def operators
    result = PdamOperator.whitelist_operator(decoded_token&.dig('resource_owner', 'username'))
    render_response(result.as_json, 200)
  end

  def inquiries
    form = Form::Pdam.new(params[:customer_number], params[:operator_id], decoded_token&.dig('resource_owner', 'username'), buyer_type)
    action = Action::PostpaidTransaction::Inquiry.new(form)
    result = action.run!
    render_response(pdam_inquiry_format(result), 200)
  end

  def create
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0
    form = Form::Pdam.new(params[:customer_number], params[:operator_id], decoded_token&.dig('resource_owner', 'username'), buyer_type)
    action = Action::PdamTransaction::Create.new(form, decoded_token[:resource_owner_id], transaction_type)
    transaction = action.run!
    render_response(transaction.as_json, 201)
  end

  def show
    super {
      |id|
        PdamTransaction.find_by_id(id)
    }
  end

  def pay
    super {
      |remote_transaction_id|
        PdamTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def invoicing
    super {
      |remote_transaction_id|
        PdamTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def confirm
    super {
      |remote_transaction_id|
        PdamTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def has_transacted
    raise Exceptions::UnauthorizedUser.new unless decoded_token.present?
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0

    super {
      PdamTransaction.find_by(buyer_id: decoded_token[:resource_owner_id])
    }
  end
end
