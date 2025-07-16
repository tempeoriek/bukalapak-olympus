class AddBukalapakAndPartnerAdminFee < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.add_column :bukalapak_admin_charge, :integer
      t.add_column :partner_admin_charge, :integer
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.remove_column :bukalapak_admin_charge
      t.remove_column :partner_admin_charge
    end
  end
end
