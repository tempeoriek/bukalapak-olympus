module Recurrence
  module Postpaid
    class Create
      include PostpaidTransactionUtility

      RECURSIVE_TEMPLATE_ENDPOINT = "#{Channel::Config::RECURSIVE_ENDPOINT}/_internal/templates"
      RECURSIVE_AUTH_KEY = "Basic #{Channel::Config::RECURSIVE_AUTH_KEY}"

      def initialize(form)
        @buyer_id = form.buyer_id
        @amount = form.amount
        @recurrence_value = form.recurrence_value
        @recurrence_type = form.recurrence_type
        @payment_method = form.payment_method
        @template = template_detail_klass_instance
        @action_date = form.action_date
      end

      def run!
        ActiveRecord::Base.transaction do
          set_template_detail
          payload = {
            user_id: @buyer_id,
            detail_id: @template.id,
            detail_type: postpaid_product,
            recurrence_value: @recurrence_value,
            recurrence_type: @recurrence_type,
            payment_method: @payment_method,
            amount: @amount
          }
          payload[:action_date] = @action_date if @action_date
          response = Channel::Connection::Http.post(RECURSIVE_TEMPLATE_ENDPOINT, RECURSIVE_AUTH_KEY, payload)
          recursive_data = JSON.parse(response)['data']
          @template.recursive_id = recursive_data['id']
          @template.save!
        end

        notify_subscribe

        log_request([postpaid_product, 'recurrence', 'create', 'success'], generate_log_message, @template.id)

        @template
      rescue => e # log the error
        log_request([postpaid_product, 'recurrence', 'create', 'failed'], generate_error_log_message(e))
        Honeybadger.notify(e)
        raise
      end

      private

      def postpaid_product
        raise NotImplementedError
      end

      def template_detail_klass_instance
        raise NotImplementedError
      end

      def set_template_detail
        raise NotImplementedError
      end

      def generate_error_log_message(e)
        raise NotImplementedError
      end

      def generate_log_message
        raise NotImplementedError
      end

      def notify_subscribe
        raise NotImplementedError
      end

      def action_date
        rValue = @recurrence_value.to_i
        rType = @recurrence_type

        today = Date.today
        year = today.year
        month = today.month
        day = today.day

        if rType == "on_date"
          startOfMonth = Date.new(today.year, today.month, 1)
          endOfMonth = startOfMonth.advance({years: 0, months: 1, days: -1})
          actMonth = (month % 12) + 1

          actMonth = month if day < rValue && day < endOfMonth.day

          actMonth = (actMonth - 1) % 12 + 1

          startOfMonth = Date.new(today.year, actMonth, 1)
          endOfMonth = startOfMonth.advance({months: 1, days: -1})
          rValue = endOfMonth.day if rValue > endOfMonth.day

          actDate = Date.new(year, actMonth, rValue)
        elsif rType == "on_month"
          actYear = year + 1
          actYear = year if month < rValue
          actDate = Date.new(actYear, rValue, 1)
        elsif rType == "days"
          actDate = today.advance({days: rValue})
        elsif rType == "months"
          actDate = today.advance({months: rValue})
        elsif rType == "years"
          actDate = today.advance({years: rValue})
        else
          raise 'unsupported recurrence value type'
        end

        actDate
      end
    end
  end
end
