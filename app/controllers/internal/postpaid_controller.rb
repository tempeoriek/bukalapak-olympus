module Internal
  class PostpaidController < ApplicationController
    include Postpaid::Constant
    include Response
    include Authenticate

    def pay(&block)
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      transaction = block.call(params[:id])
      raise Exceptions::TransactionNotFound.new unless transaction.present?
      action = Action::PostpaidTransaction::Process.new(transaction)
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

    def status(&block)
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      transaction = block.call(params[:id])
      raise Exceptions::TransactionNotFound.new unless transaction.present?

      return render_response('ok', 200) if transaction.succeeded? || transaction.failed?

      action = Action::PostpaidTransaction::ForceUpdateStatus.new(transaction, params[:status])
      action.run!

      render_response("Transaksi berhasil di#{params[:status]}", 200)
    end
  end
end
