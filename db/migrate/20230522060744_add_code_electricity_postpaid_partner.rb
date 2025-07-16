class AddCodeElectricityPostpaidPartner < ActiveRecord::Migration[5.2]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :electricity_postpaid_partners, throttler: throttler do |t|
      t.add_column :code, 'VARCHAR(255) default null'
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :electricity_postpaid_partners, throttler: throttler do |t|
      t.remove_column :code
    end
  end
end
