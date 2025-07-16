class AddUnpaidBillFlagging < ActiveRecord::Migration[5.2]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :bpjs_ketenagakerjaan_transactions, throttler: throttler do |t|
      t.add_column :unpaid_bills, 'boolean default false'
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :bpjs_ketenagakerjaan_transactions, throttler: throttler do |t|
      t.remove_column :unpaid_bills
    end
  end
end
