module Sievex
  class Send < Base
    def initialize(transaction, state)
      @transaction = transaction
      @state = state
      @event_type = EVENT_TYPE_MAP[@state.to_sym]
      @event_time = ::Time.current.to_i
      @entity_type = ENTITY_TYPE_MAP[@transaction.class]
      @tags = %w[sievex send]
      @track_id = @transaction.remote_transaction_id
    end

    def run!
      payload = create_sievex_event
      response = SieveX::Client.track(@event_type, payload)
      log_event({ payload: payload, response: response }, @tags, track_id: @track_id)
      response
    rescue => e
      @tags << 'error'
      message = "#{e.class}: #{e.message}"
      log_error(message, @tags, { track_id: @track_id })
      500
    end

    private

    def create_sievex_event
      payload = {
        entity_type: @entity_type,
        event_time:  @event_time
      }
      payload[:credit_card_bill_transaction] = credit_card_bill_transaction if @entity_type == CREDIT_CARD_BILL_ENTITY

      payload
    end

    def credit_card_bill_transaction
      # if @transaction.card_data.present?
      #   card_number = @transaction.card_number
      # else
      #   card_number = @transaction.customer_number
      # end
      # customer_number = ::CreditCardBillHelper.crypto_hash_cc_number(card_number)
      customer_number = ::CreditCardBillHelper.crypto_hash_cc_number(@transaction.card_number)
      {
        transaction_id:   @transaction.remote_transaction_id.to_s,
        transaction_type: @transaction.transaction_type,
        state:            @state,
        amount:           @transaction.amount,
        customer_number:  customer_number,
        created_at:       @transaction.created_at.to_i,
        paid_at:          @transaction.paid_at.to_i,
        buyer: {
          account_id:       @transaction.buyer_id.to_s,
          account_type:     USER
        }
      }
    end
  end
end
