module Quickpays
  class Inquiry
    include Response::Quickpay
    include QuickpayHelper

    def initialize(remote_type, today, transactions, skip_cache)
      @remote_type = remote_type
      @today = today
      @transactions = transactions
      @skip_cache = skip_cache
    end

    def run!
      results = []

      @transactions.each do |transaction|
        begin
          operator_or_biller = transaction[:operator] || transaction[:biller]
          id = operator_or_biller.nil? ? nil : operator_or_biller[:id]

          key = customer_number_key(@remote_type, @today, transaction[:customer_number], id)
          value = RedisOlympus.get(key) unless @skip_cache

          if value.nil? || @skip_cache
            form = build_form(transaction[:customer_number], id)
            result = inquiry(form)
            serialized = ResponseGeneralizer::Quickpay.new(result, @remote_type)
            response = quickpay_generic_inquiry_format(serialized)

            RedisOlympus.set(key, response.to_json, ex: expire_in(transaction))
          else
            response = JSON.parse(value).with_indifferent_access
          end

          results << response
        rescue
          next
        end
      end

      results
    end

    private

    def expire_in(transaction)
      case @remote_type
      when 'bpjs-kesehatan'
        until_end_of_month(@today)
      when 'pdam'
        [
          until_next(@today, transaction[:operator][:bill_day]),
          until_next(@today, transaction[:operator][:due_day])
        ].min
      when 'phone-credit-postpaid'
        until_end_of_week(@today)
      when 'electricity_postpaid'
        [until_end_of_month(@today), until_next(@today, 20)].min
      else
        raise 'Unsupported type'
      end
    end

    def build_form(customer_number, operator_or_biller_id)
      case @remote_type
      when 'bpjs-kesehatan'
        Form::BpjsKesehatan.new(customer_number, nil, @today.month, @today.year)
      when 'pdam'
        Form::Pdam.new(customer_number, operator_or_biller_id)
      when 'phone-credit-postpaid'
        Form::PhoneCredit.new(customer_number)
      when 'electricity_postpaid'
        Form::ElectricityPostpaid.new(customer_number)
      else
        raise 'Unsupported type'
      end
    end

    def inquiry(form)
      Action::PostpaidTransaction::Inquiry.new(form).run!
    end
  end
end
