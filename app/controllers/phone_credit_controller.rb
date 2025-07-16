# frozen_string_literal: true

class PhoneCreditController < PostpaidsController

  PRODUCT_NAME = PHONE_CREDIT_PRODUCT
  BLACKLIST_PCP_USER_IDS = ENV['BLACKLIST_PCP_USER_IDS']
  WHITELIST_LIMIT_PCP_USER_IDS = ENV.fetch('WHITELIST_LIMIT_PCP_USER_IDS', '')
  PCP_MAX_INQUIRY_ATTEMPT = ENV['PCP_MAX_INQUIRY_ATTEMPT'].to_i
  PCP_MAX_INQUIRY_ATTEMPT_NEXT_DAY_RESET_HOUR = ENV['PCP_MAX_INQUIRY_ATTEMPT_NEXT_DAY_RESET_HOUR'].to_i
  REDIS_KEY_INQUIRY_COUNTER_PREFIX = "olympus:inquiry_by_user:phone_credit_postpaid"

  def inquiries
    raise Exceptions::UnauthorizedUser.new if decoded_token.nil? || decoded_token[:resource_owner_id] == 0
    raise Exceptions::MaxInquiryAttemptExceeded.new if max_inquiry_attempt_exceeded? && !skip_limit_user_id?(decoded_token[:resource_owner_id])
    form = Form::PhoneCredit.new(params[:customer_number], decoded_token[:resource_owner_id], buyer_type)
    action = Action::PostpaidTransaction::Inquiry.new(form)
    result = action.run!
    render_response(phone_credit_inquiry_format(result), 200)
  end

  def create
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0
    form = Form::PhoneCredit.new(params[:customer_number], decoded_token[:resource_owner_id], buyer_type)
    action = Action::PhoneCreditTransaction::Create.new(form, decoded_token[:resource_owner_id], transaction_type)
    transaction = action.run!
    render_response(transaction.as_json, 201)
  end

  def show
    super {
      |id|
        PhoneCreditPostpaidTransaction.find_by_id(id)
    }
  end

  def pay
    super {
      |remote_transaction_id|
        PhoneCreditPostpaidTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def invoicing
    super {
      |remote_transaction_id|
        PhoneCreditPostpaidTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  def confirm
    super {
      |remote_transaction_id|
        PhoneCreditPostpaidTransaction.find_by(remote_transaction_id: remote_transaction_id)
    }
  end

  private

  def is_user_id_blacklisted?
    blacklist_user_ids = BLACKLIST_PCP_USER_IDS&.split(',') || []
    true if decoded_token[:resource_owner_id].present? && blacklist_user_ids.include?(decoded_token[:resource_owner_id].to_s)
  end

  def skip_limit_user_id?(user_id)
    whitelisted_user_ids = WHITELIST_LIMIT_PCP_USER_IDS&.split(',') || []
    true if whitelisted_user_ids.include?(user_id.to_s)
  end

  def max_inquiry_attempt_exceeded?
    return true if is_user_id_blacklisted?
    return false if PCP_MAX_INQUIRY_ATTEMPT < 1 # if env not set or less than 1 then no need to check

    redis_key       = "#{REDIS_KEY_INQUIRY_COUNTER_PREFIX}:#{decoded_token[:resource_owner_id]}".freeze
    attempt_counter = RedisOlympus.incr(redis_key).to_i
    reset_time      = seconds_until_next_day_hour(PCP_MAX_INQUIRY_ATTEMPT_NEXT_DAY_RESET_HOUR)

    RedisOlympus.expire(redis_key, reset_time) if attempt_counter == 1

    return attempt_counter > PCP_MAX_INQUIRY_ATTEMPT
  rescue => e
    # do nothing when redis fails
    raise unless e.kind_of?(Redis::BaseError)
  end

  def seconds_until_next_day_hour(hour = 3)
    hour = 3 if hour < 1 # set default
    now = Time.current.utc.in_time_zone('Jakarta')
    next_time = now.tomorrow.beginning_of_day + hour.hours # next day at n hour (default 03:00)
    (next_time - now).to_i
  end
end
