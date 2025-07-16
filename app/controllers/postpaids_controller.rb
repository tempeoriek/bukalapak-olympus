class PostpaidsController < ApplicationController
  include Postpaid::Constant
  include Response
  include Authenticate

  def show(&block)
    transaction = block.call(params[:id])
    raise Exceptions::TransactionNotFound.new unless transaction.present?
    raise Exceptions::UnauthorizedUser.new unless transaction.buyer_id == decoded_token[:resource_owner_id] || is_role_authorize?(decoded_token[:resource_owner][:role])

    render_response(transaction.as_json, 200)
  end

  def pay(&block)
    # basic authentication for mothership
    authenticated = http_basic_authenticate
    # this is to avoiding double render
    return unless authenticated == true

    transaction = block.call(params[:id])
    raise Exceptions::TransactionNotFound.new unless transaction.present?
    action = Action::PostpaidTransaction::Process.new(transaction, params[:payment_id])
    action.run!

    render_response(transaction.as_json, 200)
  rescue Exceptions::CannotProcessTransaction
    render_response('ok', 200)
  end

  def invoicing(&block)
    # basic authentication for mothership
    authenticated = http_basic_authenticate
    # this is to avoiding double render
    return unless authenticated == true

    transaction = block.call(params[:id])
    raise Exceptions::TransactionNotFound.new unless transaction.present?
    action = Action::PostpaidTransaction::Invoicing.new(transaction, params[:invoice_id])
    action.run!

    render_response(transaction.as_json, 200)
  end

  def confirm(&block)
    # basic authentication for mothership
    authenticated = http_basic_authenticate
    # this is to avoiding double render
    return unless authenticated == true

    transaction = block.call(params[:id])
    raise Exceptions::TransactionNotFound.new unless transaction.present?
    action = Action::PostpaidTransaction::ManualConfirm.new(transaction)
    action.run!

    render_response(transaction.as_json, 200)
  end

  def has_transacted(&block)
    transaction = block.call
    response = { has_transacted: transaction.present? }

    render_response(response.as_json, 200)
  end
end
