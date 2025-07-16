module Internal
  class BpjsKesehatanController < Internal::PostpaidController
    include Response
    include Authenticate

    PRODUCT_NAME = BPJS_KESEHATAN_PRODUCT

    def show
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      transaction = BpjsKesehatanTransaction.find_by_id(params[:id])
      raise Exceptions::TransactionNotFound.new unless transaction.present?

      render_response(transaction.as_json, 200)
    end

    def status
      super {
        |id|
          BpjsKesehatanTransaction.find_by_id(id)
      }
    end
  end
end
