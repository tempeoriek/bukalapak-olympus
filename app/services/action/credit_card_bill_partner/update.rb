module Action
  module CreditCardBillPartner
    class Update

      def initialize(params, partner)
        @params = params
        @partner = partner
      end

      def run!
        prev_active_partner = @params[:credit_card_biller].partner
        if @params[:state] == 1 && prev_active_partner && prev_active_partner != @partner
          prev_active_partner.with_lock do
            prev_active_partner.state = 'inactive'
            prev_active_partner.save!
            update_partner
          end
        elsif @params[:state] == 0 && prev_active_partner && prev_active_partner == @partner
          raise Exceptions::AtLeastOnePartnerActive if prev_active_partner.id == @partner.id
        else
          update_partner
        end

        @partner
      end

      def update_partner
        @partner.update_attributes!(@params)
      end
    end
  end
end
