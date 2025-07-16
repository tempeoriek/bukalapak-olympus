# frozen_string_literal: true

module Channel
  module NewBNI
    class CreditCardBill
      attr_accessor :object

      BNI_BILLER_CODE = Channel::Config::BNI_BILLER_CODE.freeze

      # object can be:
      # - Form::CreditCardBill
      # - CreditCardBillTransaction
      #
      # TODO: Rework this method to suit the needs!
      def initialize(object)
        @object = object
      end

      def inquiry_to_partner
        Channel::NewBNI::Request::Inquiry.new(@object).perform
      end

      def create_transaction
        #in here object can only be transaction
        if @object.biller.biller_code == BNI_BILLER_CODE
          Channel::NewBNI::Request::PaymentBNI.new(@object).perform
        else
          Channel::NewBNI::Request::PaymentNonBNI.new(@object).perform
        end
      end

      def get_transaction_list
        # TODO: implement this when it's ready
      end

      # same with the old BNI
      def confirm_transaction
        raise ::Exceptions::ManualCheckError.new("BNI")
      end

      def can_confirm?
        false
      end
    end
  end
end
