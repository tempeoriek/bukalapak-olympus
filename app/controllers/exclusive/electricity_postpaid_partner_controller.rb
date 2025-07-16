module Exclusive
  class ElectricityPostpaidPartnerController < ::PostpaidsController

    before_action :authorize!

    PRODUCT_NAME = ELECTRICITY_PRODUCT

    def list
      result = []
      ElectricityPostpaidPartner.all.each do |partner|
        result << serialize(partner)
      end
      render_response(result, 200)
    rescue Exceptions::PostpaidError => e
      render_error(e)
    end

    def update
      body = JSON.parse(request.body.read).with_indifferent_access
      form = Form::ElectricityPostpaidPartner.new(body)
      partner = ElectricityPostpaidPartner.find(params[:id])
      is_switch = partner.state != body[:state]
      is_balance_available = params.key?(:balance) && !!params[:balance]
      @partner_name = partner.name
      ActiveRecord::Base.transaction do
        partner.update_attributes!(form.update_params.except(:balance))

        deactive_others! if is_switch

        update_partner_balance! if is_balance_available
      end

      render_response(serialize(partner), 200)
    rescue Exceptions::PostpaidError => e
      render_error(e)
    end

    def get_balance
      response = Action::ElectricityTransaction::Exclusive::GetBalance.new.run!

      render_response(response, 200)
    rescue Exceptions::PostpaidError => e
      render_error(e)
    end

    def modify_balance
      form = Form::ElectricityPostpaidBalance.new(params)
      response = Action::ElectricityTransaction::Exclusive::UpdateBalance.new(form).run!

      render_response(response, 200)
    rescue Exceptions::PostpaidError => e
      render_error(e)
    end

    private

    def deactive_others!
      ElectricityPostpaidPartner.all.each do |partner|
        next if partner.id == params[:id].to_i
        partner.update!(state: "inactive")
      end
    end

    def update_partner_balance!
      partner_balances = ElectricityPostpaidPartner.find(params[:id]).electricity_postpaid_partners_balances
      params[:balance].each do |balance|
        selected_balance = partner_balances.find_by(type: balance[:type])

        raise Exceptions::BalanceTypeNotFound if selected_balance.nil?
        raise Exceptions::InvalidParameterError.new('Invalid balance amount') if balance[:amount].to_i <= 0
        raise Exceptions::InvalidParameterError.new('Invalid threshold amount') if balance[:threshold].to_i <= 0

        selected_balance.update(amount: balance[:amount], threshold: balance[:threshold])

        update_metric!(balance)
      end
    end

    def update_metric!(balance)
      balance_metric_key = {
        bukalapak: Observer::Metric::TAGLIS_BALANCE,
        mitra: Observer::Metric::TAGLIS_BALANCE_MITRA,
        bukaconnect: Observer::Metric::TAGLIS_BALANCE_BUKACONNECT
      }[balance[:type].to_sym]

      threshold_metric_key = {
        bukalapak: Observer::Metric::TAGLIS_THRESHOLD,
        mitra: Observer::Metric::TAGLIS_THRESHOLD_MITRA,
        bukaconnect: Observer::Metric::TAGLIS_THRESHOLD_BUKACONNECT
      }[balance[:type].to_sym]

      balance_metric_partner_key = "#{balance_metric_key.to_s}_#{@partner_name}".to_sym
      threshold_metric_partner_key = "#{threshold_metric_key.to_s}_#{@partner_name}".to_sym

      Observer.gauge(balance_metric_partner_key, balance[:amount])
      Observer.gauge(threshold_metric_partner_key, balance[:threshold])
    end

    def authorize!
      token = get_token(request.env['HTTP_AUTHORIZATION'])
      decoded_token = JsonWebToken.decode(token)
      raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end

    def serialize(provider)
      Serializer::Exclusive::ElectricityPostpaidPartner.new(provider)
    end
  end
end
