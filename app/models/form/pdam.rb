module Form
  class Pdam < Base
    attr_accessor :customer_number, :operator_id, :operator, :partner, :buyer_type

    def initialize(customer_number, operator_id, username=nil, buyer_type = NORMAL_BUYER_TYPE)
      @customer_number = customer_number
      @buyer_type = buyer_type
      operator = ::PdamOperator.find_by_id(operator_id)
      raise ::Exceptions::InvalidPdamOperator.new if operator.nil? || !operator.active?
      @operator = operator
      @operator_id = operator_id
      # TO purposes only
      if dji_whitelist?(username)
        @partner = 'dji-pdam-to'
      else
        @partner = operator.partner
      end

      # Whitelist PDAM operator
      raise ::Exceptions::InvalidPdamOperator.new if affected_operator?(operator.code) && !whitelist_user_operator?(username)
    end

    def customer_number
      @customer_number
    end

    def operator_id
      @operator_id
    end

    def operator
      @operator
    end

    def partner
      @partner
    end

    def dji_whitelist?(username)
      username && (WhitelistPdamTo.include?(username) || ENV['WHITELIST_ALL_USER'].downcase == 'true') && @operator.partner == 'dji'
    end

    def affected_operator?(code)
      WhitelistPdamOperatorCodes.include?(code) && Toggles::WhitleistPdamAllOperator.active? == false
    end

    def whitelist_user_operator?(username)
      WhitelistPdamUsername.include?(username)
    end

    def is_mitra?
      @buyer_type == AGENT_BUYER_TYPE || @buyer_type == COLLECTING_AGENT_BUYER_TYPE
    end

    def valid?
      !@customer_number.blank?
    end
  end
end
