module Internal
  class BpjsKetenagakerjaanController < Internal::PostpaidController

    PRODUCT_NAME = BPJS_KETENAGAKERJAAN_PRODUCT

    def pay
      super {
        |remote_transaction_id|
          BpjsKetenagakerjaanTransaction.find_by(remote_transaction_id: remote_transaction_id)
      }
    end

    def confirm
      super {
        |remote_transaction_id|
          BpjsKetenagakerjaanTransaction.find_by(remote_transaction_id: remote_transaction_id)
      }
    end

    def invoicing
      super {
        |remote_transaction_id|
          BpjsKetenagakerjaanTransaction.find_by(remote_transaction_id: remote_transaction_id)
      }
    end

    def status
      super {
        |id|
          BpjsKetenagakerjaanTransaction.find_by_id(id)
      }
    end

    def show
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      transaction = BpjsKetenagakerjaanTransaction.find_by_id(params[:id])
      raise Exceptions::TransactionNotFound.new unless transaction.present?

      render_response(transaction.as_json, 200)
    end
  end
end
