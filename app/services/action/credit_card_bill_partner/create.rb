module Action
  module CreditCardBillPartner
    class Create

      DEFAULT_TERMS_AND_CONDITIONS = "<ol><li>Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</li><li>Biaya admin akan ditambahkan pada tagihan di bulan berikutnya.</li></ol>"

      def initialize(params)
        @params = params
      end

      def run!
        if @params[:state] == 1
          prev_active_partner = @params[:credit_card_biller].partner

          prev_active_partner.with_lock do
            prev_active_partner.state = 'inactive'
            prev_active_partner.save!
            create_partner
          end
        else
          create_partner
        end
      end

      def create_partner
        partner =  ::CreditCardBillPartner.new(
          name: @params[:name],
          terms_and_conditions: @params[:terms_and_conditions] || DEFAULT_TERMS_AND_CONDITIONS,
          biller_code: @params[:biller_code],
          bukalapak_admin_charge: @params[:bukalapak_admin_charge],
          partner_admin_charge: @params[:partner_admin_charge],
          credit_card_biller_id: @params[:credit_card_biller_id],
          state: @params[:state],
          revenue: @params[:revenue],
        )
        partner.save!
        partner
      end
    end
  end
end
