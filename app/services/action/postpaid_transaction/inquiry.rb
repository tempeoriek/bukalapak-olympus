module Action
  module PostpaidTransaction
    class Inquiry
      include PostpaidTransactionUtility
      include Action::PostpaidTransaction::Autoswitch

      def initialize(form)
        @form = form
      end

      def run!
        channel = Channel.new_partner_channel(@form)
        response = channel.inquiry_to_partner

        # If the inquiry is successful, the code at the bottom will run
        # and the autoswitch value will be saved with `:success` status.
        # Otherwise, the autoswitch record method will be triggered within each partner inquiry method.
        options = {}
        options[:operator_id] = channel.operator_id if channel.respond_to?(:operator_id)

        record_autoswitch_value('inquiry', :success, channel.product_type, options) if channel.respond_to?(:product_type)

        response
      end
    end
  end
end
