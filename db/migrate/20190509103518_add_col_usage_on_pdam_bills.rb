class AddColUsageOnPdamBills < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 0.2)
    Lhm.change_table :pdam_bills, throttler: throttler do |t|
      t.add_column :usage, :integer
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 0.2)
    Lhm.change_table :pdam_bills, throttler: throttler do |t|
      t.remove_column :usage
    end
  end
end
