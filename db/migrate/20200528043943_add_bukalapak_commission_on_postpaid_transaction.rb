class AddBukalapakCommissionOnPostpaidTransaction < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 0.2)
    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.add_column :bukalapak_commission, "mediumint unsigned default 0"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 0.2)
    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.remove_column :bukalapak_commission
    end
  end
end
