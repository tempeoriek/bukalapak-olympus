class AddSegelRetributionStandmeterRefnoToPdamTransactions < ActiveRecord::Migration[5.2]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.add_column :reference_number, "VARCHAR(255) default null"
      t.add_column :stand_meter, "VARCHAR(255) default null"
      t.add_column :retribution, "integer default 0"
      t.add_column :segel, "integer default 0"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.remove_column :reference_number
      t.remove_column :stand_meter
      t.remove_column :retribution
      t.remove_column :segel
    end
  end
end
