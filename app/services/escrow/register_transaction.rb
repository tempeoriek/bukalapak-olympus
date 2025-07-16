module Escrow
  class RegisterTransaction
    include PostpaidTransactionUtility
    include ConnectionUtility
    URL = "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/remote/transactions".freeze

    def initialize(transaction, expiration_time_in_hour: 10)
      @transaction = transaction
      @expiration_time_in_hour = expiration_time_in_hour
    end

    def run!
      payload = {
        remote_id: @transaction.id,
        buyer_id: @transaction.buyer_id,
        amount: @transaction.amount,
        remote_type: generate_remote_type(@transaction),
        expiration_time: Time.now + (@expiration_time_in_hour || 10).hours
      }

      response = Escrow::Connection.post(URL, payload)
      response = parse_response(response)
      log_success('create_transaction', URL, payload, response, @transaction.id)
      response[:data]
    rescue ::RestClient::Exception => e
      log_and_raise_error('create_transaction', URL, payload, e.message, @transaction.id)
    end

    private

    def parse_response(response)
      JSON.parse(response).with_indifferent_access
    end
  end
end
