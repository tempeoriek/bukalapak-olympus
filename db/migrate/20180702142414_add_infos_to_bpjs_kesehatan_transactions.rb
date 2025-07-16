class AddInfosToBpjsKesehatanTransactions < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.add_column :reference_number, "VARCHAR(255) default null"
      t.add_column :info, "VARCHAR(255) default null"
      t.add_column :phone_number, "VARCHAR(255) default ''"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.remove_column :reference_number
      t.remove_column :info
      t.remove_column :phone_number
    end
  end
end
