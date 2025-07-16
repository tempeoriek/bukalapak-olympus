class AddDetailPdamTransactionsAttribute < ActiveRecord::Migration[5.2]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.add_column :details, :json
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.remove_column :details
    end
  end
end
