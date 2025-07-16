module Form
    class PdamOperatorCommissionSetting < Base
      attr_accessor :operator_id, :value, :state, :min_transaction_value, :max_transaction_value

      def initialize(params)
        raise ::Exceptions::InvalidParameterError.new('missing param') if params[:operator_id].nil? || params[:value].nil? || params[:min_transaction_value].nil? || params[:max_transaction_value].nil?
        raise ::Exceptions::InvalidParameterError.new('Value cannot be larger than 100000000') if params[:value].to_i > 100_000_000
        raise ::Exceptions::InvalidParameterError.new('Min transaction value cannot be less than 0') if params[:min_transaction_value].to_i < 0
        raise ::Exceptions::InvalidParameterError.new('Min transaction value cannot be larger than max transaction value') if params[:min_transaction_value].to_i > params[:max_transaction_value].to_i
        raise ::Exceptions::InvalidParameterError.new('State can only be active or inactive') unless ['active', 'inactive'].include?(params[:state])

        @operator_id = params[:operator_id].to_i
        @value = params[:value].to_i
        @state = params[:state]
        @min_transaction_value = params[:min_transaction_value].to_i
        @max_transaction_value = params[:max_transaction_value].to_i
      end
    end
end

