class RemovePaidUntilFromBpjsKetenagakerjaanTransactions < ActiveRecord::Migration[5.2]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :bpjs_ketenagakerjaan_transactions, throttler: throttler do |t|
      t.remove_column :paid_until
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :bpjs_ketenagakerjaan_transactions, throttler: throttler do |t|
      t.add_column :paid_until, "VARCHAR(255) default null"
    end
  end
end
