module Escrow
  class RetrieveDeposit

    def initialize(user_id, options = {})
      @user_id = user_id
    end

    def run!
      @url = ENV['MOTHERSHIP_INTERNAL_RETRIEVE_DEPOSIT'] % [@user_id]
      
      response = Escrow::Connection.get(@url)
      response = parse_response(response)
      response[:data]
    end

    private

    def parse_response(response)
      JSON.parse(response).with_indifferent_access
    end
  end
end
