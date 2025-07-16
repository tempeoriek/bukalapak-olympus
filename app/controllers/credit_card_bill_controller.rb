class CreditCardBillController < PostpaidsController

  before_action :check_toggle, only: [:billers, :inquiries, :create]

  PRODUCT_NAME = CREDIT_CARD_BILL_PRODUCT
  CC_LIMIT_CREATE_TRX_ACTIVE = ENV['CC_LIMIT_CREATE_TRX_ACTIVE']&.downcase

  def billers
    # result = CreditCardBiller.where(active: true)
    result = get_billers
    result = result.sort_by{ |rs| rs.name.downcase }
    render_response(result.as_json, 200)
  rescue Exceptions::PostpaidError => e
    render_error(e)
  end

  def inquiries
    form = Form::CreditCardBill.new(params[:customer_number], params[:biller_id], username: username, buyer_id: decoded_token&.dig('resource_owner', 'id'))
    if form.partner.name == 'pnl'
      return render_response(credit_card_bill_pnl_inquiry_format(form), 200)
    elsif form.partner.name == 'visa'
      return render_response(credit_card_bill_visa_inquiry_format(form), 200)
    elsif form.partner.name == 'cimbniaga_thor'
      return render_response(credit_card_bill_visa_inquiry_format(form), 200)
    end
    result = Action::PostpaidTransaction::Inquiry.new(form).run!
    render_response(credit_card_bill_inquiry_format(result), 200)
  end

  def create
    raise Exceptions::UnauthorizedUser.new if decoded_token == nil || decoded_token[:resource_owner_id] == 0
    incr_and_check_create_transaction_limit if CC_LIMIT_CREATE_TRX_ACTIVE == 'true'

    form = Form::CreditCardBill.new(params[:customer_number], params[:biller_id], params[:amount], username: username, buyer_id: decoded_token&.dig('resource_owner', 'id'))
    action = Action::CreditCardBillTransaction::Create.new(form, decoded_token[:resource_owner_id], transaction_type)
    transaction = action.run!
    render_response(transaction.as_json, 201)
  end

  def incr_and_check_create_transaction_limit
    redis_key = "olympus:create_trx_by_user:credit_card_bill:#{decoded_token['resource_owner_id']}"
    threshold = ENV['CC_LIMIT_CREATE_TRX_THRESHOLD']&.to_i || 1
    expire_seconds = ENV['CC_LIMIT_CREATE_TRX_SECONDS']&.to_i || 120

    # set default to 0 if it return nil (no transaction has been made in 2 minute)
    trx_counter = RedisOlympus.get(redis_key).to_i

    if trx_counter < threshold
      RedisOlympus.incr(redis_key)
      RedisOlympus.expire(redis_key, expire_seconds)
    else
      raise Exceptions::TransactionCreatedExceedsLimit.new
    end
  rescue => e
    # do nothing when redis fails
    if !e.kind_of?(Redis::BaseError)
      raise
    end
  end

  def show
    super {
      |id|
        CreditCardBillTransaction.find_by_id(id)
    }
  end

  private

  def check_toggle
    raise Exceptions::FeatureToggledOff unless GeneralCircuitBreaker::CreditCardBill.instance.allow?
    raise Exceptions::FeatureToggledOff unless Toggles::CreditCardBill.active?
  end

  def get_billers
    result = CreditCardBiller.where(active: true)

    # visa whitelist on
      # non whitelisted username = show all but not visa
      # whitelisted username     = show all
    # visa whitelist off         = show all

    if Toggles::WhitelistVisa.active? && visa_not_whitelisted_username?
      # WhitelistVisaPartnerIDs -> Check here config/initializers/whitelist_visa.rb
      active_partner_biller_ids = CreditCardBillPartner.where(state: ACTIVE)
                                                       .where.not(:id => WhitelistVisaPartnerIDs)
                                                       .map { |partner| partner.credit_card_biller_id }
      return result.where(id: active_partner_biller_ids)
    end
    result
  end

  def visa_not_whitelisted_username?
    username.blank? || WhitelistVisa.exclude?(username)
  end
end
