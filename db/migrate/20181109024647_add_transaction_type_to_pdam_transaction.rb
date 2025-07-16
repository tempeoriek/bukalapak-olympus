class AddTransactionTypeToPdamTransaction < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.add_column :transaction_type, :integer
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.remove_column :transaction_type
    end
  end
end
