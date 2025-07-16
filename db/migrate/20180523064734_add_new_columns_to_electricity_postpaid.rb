class AddNewColumnsToElectricityPostpaid < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.add_column :unpaid_bill, :integer
      t.add_column :reference_number, "VARCHAR(255) default null"
      t.add_column :info_text, "VARCHAR(255) default null"
      t.add_column :bukalapak_admin_charge, :integer
      t.add_column :partner_admin_charge, :integer

      t.change_column :amount, :bigint
    end

    Lhm.change_table :bills, throttler: throttler do |t|
      t.change_column :amount, :bigint
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.remove_column :unpaid_bill
      t.remove_column :reference_number
      t.remove_column :info_text
      t.remove_column :bukalapak_admin_charge
      t.remove_column :partner_admin_charge

      t.change_column :amount, :integer
    end

    Lhm.change_table :bills, throttler: throttler do |t|
      t.change_column :amount, :integer
    end
  end
end
