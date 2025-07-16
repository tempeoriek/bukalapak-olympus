module QuickpayHelper
  # quickpay cache prefix, change this if update cache payload
  CACHE_PREFIX = 20180919

  def quickpays_list_key(remote_type, user_id)
    "olympus:#{CACHE_PREFIX}-#{remote_type}-index-#{user_id}"
  end

  def customer_number_key(remote_type, date, number, id)
    if id.nil?
      "olympus:#{CACHE_PREFIX}-#{remote_type}-#{date.year}-#{date.month}-#{number}"
    else
      "olympus:#{CACHE_PREFIX}-#{remote_type}-#{date.year}-#{date.month}-#{id}-#{number}"
    end
  end

  def until_end_of_month(date)
    ((date.end_of_month - date) / 1.seconds).round
  end

  def until_end_of_week(date)
    ((date.end_of_week - date) / 1.seconds).round
  end

  def until_next(date, day)
    day = date.tomorrow.day if day.nil?
    if date.day >= day
      month = date.month + 1
      year = date.year

      if month > 12
        month = month - 1
        year = date.year + 1
      end

      next_day = Time.new(year, month, day) rescue date.tomorrow.beginning_of_day
    else
      next_day = Time.new(date.year, date.month, day) rescue date.tomorrow.beginning_of_day
    end

    ((next_day - date) / 1.seconds).round
  end
end
