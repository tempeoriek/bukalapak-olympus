module Action
  module PdamTransaction
    class UpdateStatus < Action::PostpaidTransaction::UpdateStatus
      THOR_PARTNERS = %w[vsi_thor mkm_thor fortuna_thor bms_thor].freeze

      def initialize(transaction, response)
        super(transaction, response)
      end

      def run!
        super
      end

      private

      def update_succeeded_transaction!
        return if @response.bills.length != @transaction.pdam_bills.length

        ActiveRecord::Base.transaction do
          @transaction.address = @response.address if @response.address.present?
          @transaction.reference_number = @response.reference_number
          ActiveRecord::Base.transaction do
            @transaction.pdam_bills.zip(@response.bills).each do |bill, bill_response|
              bill.lock!
              bill.cubication = bill_response[:cubication]
              bill.tariff = bill_response[:tariff]
              bill.penalty_fee = bill_response[:penalty_fee]
              bill.amount = bill_response[:amount]
              bill.bill_period = bill_response[:bill_period]
              bill.usage = bill_response[:usage]
              bill.save!
            end
          end
          save_attribute_thor_partners

          @transaction.save!
        end
      end

      def save_attribute_thor_partners
        if THOR_PARTNERS.include? @transaction.operator.partner
          @transaction.stand_meter = @response.stand_meter
          @transaction.retribution = @response.retribution
          @transaction.segel = @response.segel
          @transaction.details = @response.details
        end
      end
    end
  end
end
