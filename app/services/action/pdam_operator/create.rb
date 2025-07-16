module Action
  module PdamOperator
    class Create
      def initialize(params)
        @params = params
      end

      def run!
        operator =  ::PdamOperator.new(
                      name: @params[:name],
                      code: @params[:code],
                      active: @params[:active],
                      group: @params[:group],
                      image_url: @params[:image_url],
                      partner: @params[:partner],
                      bukalapak_admin_charge: @params[:bukalapak_admin_charge],
                      partner_admin_charge: @params[:partner_admin_charge],
                      bill_day: @params[:bill_day],
                      due_day: @params[:due_day],
                      terms_and_conditions: @params[:terms_and_conditions],
                      revenue: @params[:revenue],
                      update_selling_price: @params[:update_selling_price]
                    )
        operator.save!
        operator
      end
    end
  end
end
