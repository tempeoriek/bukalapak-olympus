module Response
  module Quickpay
    extend ActiveSupport::Concern
    include Postpaid::Constant

    def quickpay_generic_inquiry_format(result)
      today = Time.now
      due_day = result.due_day

      provider = result.provider
      operator = result.operator
      biller = result.biller
      image_url = result.image_url ||
        provider&.dig(:logo_url)   ||
        operator&.dig(:image_url)  ||
        biller&.dig(:image_url)

      due_date = next_date(today, due_day)
      countdown = parse_countdown(today, due_date)

      {
        remote_type: result.remote_type,
        customer_number: result.customer_number,
        customer_name: result.customer_name,
        amount: result.amount,
        paid_until: result.paid_until,
        provider: provider,
        operator: operator,
        biller: biller,
        image_url: image_url,
        countdown: countdown,
        due_date: due_date,
        severity: severity(countdown),
        descriptions: build_descriptions(result),
        amount_details: build_amount_details(result)
      }.compact
    end

    def next_date(today, due_day)
      return nil if due_day.nil?

      if today.day >= due_day
        month = today.month + 1
        year = today.year

        if month > 12
          month = month - 1
          year = today.year + 1
        end

        Time.new(year, month, due_day)
      else
        Time.new(today.year, today.month, due_day)
      end
    rescue
      today.tomorrow.beginning_of_day
    end

    def parse_countdown(today, due_date)
      return nil if due_date.nil?

      time_remaining = due_date - today
      day = (time_remaining / 1.day).round
      hour = (time_remaining / 1.hour).round
      minute = (time_remaining / 1.minute).round

      { day: day, hour: hour, minute: minute }
    end

    # normal, critical, overdue
    def severity(countdown)
      return nil if countdown.nil?

      return "critical" if countdown[:day] <= 1

      "normal"
    end

    def build_descriptions(result)
      descriptions = []
      remote_type = result.remote_type
      result.descriptions.each do |key, title|
        subtitle = result.public_send(key)

        descriptions << { title: title[remote_type] || title, subtitle: subtitle.to_s } unless subtitle.nil?
      end

      descriptions.any? ? descriptions : nil
    end

    def build_amount_details(result)
      nil
    end
  end
end
