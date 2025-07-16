class AddTariffToPdamBills < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_bills, throttler: throttler do |t|
      t.add_column :tariff, "VARCHAR(255) default null"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_bills, throttler: throttler do |t|
      t.remove_column :tariff
    end
  end
end
