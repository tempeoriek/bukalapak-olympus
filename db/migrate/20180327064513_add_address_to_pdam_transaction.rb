class AddAddressToPdamTransaction < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.add_column :address, "VARCHAR(255) default null"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.remove_column :address
    end
  end
end
