class AddRevenueColumnsOnCreditCardBillTables < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 0.2)
    Lhm.change_table :credit_card_bill_partners, throttler: throttler do |t|
      t.add_column :revenue,    "mediumint unsigned default 0"
    end
    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.add_column :revenue,    "mediumint unsigned default 0"
      t.add_column :revenue_at, :datetime
      t.add_index  :revenue_at
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 0.2)
    Lhm.change_table :credit_card_bill_partners, throttler: throttler do |t|
      t.remove_column :revenue
    end
    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.remove_index  :revenue_at
      t.remove_column :revenue_at
      t.remove_column :revenue
    end
  end
end
