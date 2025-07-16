module Channel
  module Bukopin
    class ElectricityPostpaid < Base
      include ::Postpaid::Constant
      attr_reader :tclose, :topen

      def initialize(object)
        @object = object
        @tclose = Time.zone.parse('22:45')
        @topen  = Time.zone.parse('01:00')
      end

      def inquiry_to_partner
        raise ::Exceptions::ClosedTimeError.new(@tclose, @topen) if is_closed_time?
        response = Requests::Inquiry.new(@object.customer_number, buyer_type: @object.buyer_type).run!
        build_response_generalizer(response)
      end

      def create_transaction
        inquiry_response = {}
        begin
          inquiry_response = Requests::Inquiry.new(@object.customer_number, track_id: @object.remote_transaction_id, read_timeout: Constants::DEFAULT_TIMEOUT, buyer_type: @object.buyer_type).run!
        rescue => e
          @object.update!(state: 'paid')
          log_entry = {
            payload: @object.customer_number
          }
          tags = self.class.name.split('::').map { |s| s.underscore } + %w(inquiry_payment error)
          LogBook.error(e.message, tags, e.backtrace.take(5), log_entry, track_id: @object.remote_transaction_id)
          raise e
        end

        @object.update(reference_number: inquiry_response[:reference_number])

        response_total_amount = inquiry_response[:amount] + inquiry_response[:admin_charge]
        validate_amount(response_total_amount)

        final_response = begin
          payment_iso_obj = Requests::Payment.new(inquiry_response, track_id: @object.remote_transaction_id, buyer_type: @object.buyer_type)
          payment_iso_obj.run!
        rescue Exceptions::SocketConnectionTimeout, SystemCallError => e
          reverse(payment_iso_obj.payload_object, track_id: @object.remote_transaction_id, buyer_type: @object.buyer_type)
        end

        generalized_response = build_response_generalizer(final_response)
        generalized_response.status = PARTNER_STATUS[BUKOPIN][final_response[:status]]
        generalized_response.reference_number = final_response[:reference_number] || inquiry_response[:reference_number]
        generalized_response
      end

      private

      RETRY_THRESHOLD = 3

      # Reverse is very similar to `confirm`
      # However, we can't reconstruct bit 48 from DB,
      # Hence reverse has to be done synchronously with payment
      def reverse(payment_request_iso_obj, track_id: nil, buyer_type:)
        RETRY_THRESHOLD.times do |retry_count|
          begin
            return Requests::Reversal.new(payment_request_iso_obj,
              retry_count: retry_count,
              track_id: track_id,
              buyer_type: buyer_type
            ).run!
          rescue Exceptions::SocketConnectionTimeout, SystemCallError => e
            # do nothing, retry!
          end
        end

        # sangkutin if reverse keeps timing out
        {status: ::Postpaid::Constant::BUKOPIN_PENDING}
      end

      def validate_amount(response_total_amount)
        if response_total_amount != @object.amount
          raise Exceptions::AmountMismatch.new(bl_amount: @object.amount, partner_amount: response_total_amount)
        end
      end

      def build_response_generalizer(response)
        result = ResponseGeneralizer::ElectricityPostpaid.new(response, @object.partner_object)
        result.partner_transaction_id = response.dig(:raw_data, 11)
        result.bills = build_bills(response)
        result.customer_number = response[:customer_number]&.strip
        result.customer_name = response[:customer_name]&.strip
        result.segmentation = response[:segmentation]&.strip
        result.power = response[:power]
        result.stand_meter = response[:stand_meter]
        result.outstanding_bill = response[:outstanding_bill]
        result.unpaid_bill = response[:unpaid_bill]
        result.penalty_fee = total_penalty_fee(result.bills)
        result.amount = response[:amount] + result.admin_charge if response[:amount].present?
        result.reference_number = response[:reference_number]
        result.info_text = response[:info_text]
        result
      end

      def total_penalty_fee(bills)
        bills&.map { |bill| bill[:penalty_fee] }&.inject(0, :+).to_i
      end

      def build_bills(response)
        response[:bills]&.map do |bill|
          {
            bill_period: ::Converter::StringToDate.convert(bill[:bill_period], string_format: Postpaid::Constant::YYYYMM),
            due_date: ::Converter::StringToDate.convert(bill[:due_date], string_format: Postpaid::Constant::DDMMYYYY),
            amount: bill[:amount]&.to_i,
            penalty_fee: bill[:penalty_fee]&.to_i,
            previous_meter: bill[:previous_meter],
            current_meter: bill[:current_meter]
          }
        end
      end

      def is_closed_time?
        tnow = Time.zone.now
        @tclose <= tnow || tnow <= @topen
      end
    end
  end
end
