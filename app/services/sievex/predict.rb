module Sievex
  class Predict < Base
    def initialize(transaction)
      @transaction = transaction
      @entity_type = ENTITY_TYPE_MAP[@transaction.class]
      @tags = %w[sievex predict]
      @track_id = @transaction.remote_transaction_id
    end

    def run!
      response = SieveX::Client.predict(@track_id.to_s, @entity_type)
      log_event({ entity_type: @entity_type, transaction_id: @track_id, response: response }, @tags, track_id: @track_id)
      response.data
    rescue => e
      @tags << 'error'
      message = "#{e.class}: #{e.message}"
      log_error(message, @tags, { track_id: @track_id })
    end
  end
end
