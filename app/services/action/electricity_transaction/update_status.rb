module Action
  module ElectricityTransaction
    class UpdateStatus < Action::PostpaidTransaction::UpdateStatus

      def initialize(transaction, response)
        super(transaction, response)
      end

      def run!
        super
      end

      private

      def update_succeeded_transaction!
        save_mandatory_attributes

        @transaction.info_text = @response.info_text
        @transaction.reference_number = @response.reference_number
        @transaction.save!

        if [BUKOPIN, TEKTAYA, TEKTAYA_BUKACONNECT].include?(@transaction.partner) && @response.status == SUCCESS
          Action::ElectricityTransaction::Exclusive::DeductBalance.new(@transaction).run!
        end
      end

      def save_mandatory_attributes
        @transaction.power = @response.power if @response.power.present?
        @transaction.segmentation = @response.segmentation if @response.segmentation.present?
        @transaction.stand_meter = @response.stand_meter if @response.stand_meter.present?
      end

      def update_failed_transaction!
        @transaction.info_text = @response.message if @response.message.present?
        @transaction.save!
      end
    end
  end
end
