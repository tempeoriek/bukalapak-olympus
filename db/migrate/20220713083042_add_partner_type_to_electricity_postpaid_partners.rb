class AddPartnerTypeToElectricityPostpaidPartners < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 0.2)
    Lhm.change_table :electricity_postpaid_partners, throttler: throttler do |t|
      t.add_column :partner_type, :integer
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :electricity_postpaid_partners, throttler: throttler do |t|
      t.remove_column :partner_type
    end
  end
end
