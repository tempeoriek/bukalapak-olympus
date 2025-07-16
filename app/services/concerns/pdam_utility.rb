module PdamUtility
  def bill_usage(cubication)
    before, after = cubication.split('-')
    after.to_i - before.to_i
  rescue StandardError
    0
  end

  def total_penalty_fee(bills)
    bills.map { |bill| bill[:penalty_fee].to_i }.inject(0, :+)
  end

  def calculate_total_amount(bills)
    bills.map { |bill| bill[:amount].to_i }.inject(0, :+)
  end

  def calculate_total_usage(bills)
    bills.map { |bill| bill[:usage].to_i }.inject(0, :+)
  end

  def start_bill_period(bills)
    bills&.select { |bill| !bill[:bill_period].nil? }&.map { |bill| bill[:bill_period] }&.min
  end

  def end_bill_period(bills)
    bills&.select { |bill| !bill[:bill_period].nil? }&.map { |bill| bill[:bill_period] }&.max
  end

  def total_retribution(bills)
    bills.map { |bill| bill[:waste].to_i }.inject(0, :+)
  end

  def total_segel(bills)
    bills.map { |bill| bill[:stamp_duty].to_i }.inject(0, :+)
  end
end
