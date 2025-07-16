module ResponseGeneralizer
  class Pdam
    attr_accessor :customer_number, :customer_name, :start_bill_period, :end_bill_period
    attr_accessor :start_usage_meter, :end_usage_meter
    attr_accessor :partner, :amount, :penalty_fee, :address, :bills, :usage
    attr_accessor :bukalapak_admin_charge, :partner_admin_charge, :operator
    attr_accessor :partner_transaction_id, :status
    attr_accessor :stand_meter, :segel, :retribution, :reference_number
    attr_accessor :details, :bills_period

    def initialize(&block)
      yield self if block_given?
    end

    def operator
      {
        id: @operator&.id,
        name: @operator&.name,
        group: @operator&.group,
        image_url: @operator&.image_url,
        terms_and_conditions: @operator&.terms_and_conditions
      }
    end

    def admin_charge
      bukalapak_admin_charge + partner_admin_charge
    end

    def bills_period
      return nil unless start_bill_period.present? && end_bill_period.present?

      same_month = start_bill_period.month == end_bill_period.month
      same_year = start_bill_period.year == end_bill_period.year

      return "#{I18n.l(start_bill_period, format: :short_month)} - #{I18n.l(end_bill_period, format: :short_month)}" unless same_month && same_year

      "#{start_bill_period.day} - #{end_bill_period.day} #{I18n.l(start_bill_period, format: '%b %Y')}"
    end
  end
end
