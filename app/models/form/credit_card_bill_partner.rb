module Form
  class CreditCardBillPartner < Base

    def initialize(params)
      @params = params
    end

    def create_params
      biller = ::CreditCardBiller.find_by_id(@params[:biller_id])
      raise Exceptions::BillerNotFound unless biller

      @params.merge!({
        state: state,
        credit_card_biller_id: biller.id,
        credit_card_biller: biller,
      }).except(:active)
    end

    def update_params
      params_hash = create_params
      {
        name: params_hash[:name],
        terms_and_conditions: params_hash[:terms_and_conditions],
        biller_code: params_hash[:biller_code],
        bukalapak_admin_charge: params_hash[:bukalapak_admin_charge],
        partner_admin_charge: params_hash[:partner_admin_charge],
        credit_card_biller_id: params_hash[:credit_card_biller_id],
        credit_card_biller: params_hash[:credit_card_biller],
        state: params_hash[:state],
        revenue: params_hash[:revenue],
      }
    end

    private

    def state
      @params[:active] ? ::Postpaid::Constant::ACTIVE : ::Postpaid::Constant::INACTIVE
    end

  end
end
