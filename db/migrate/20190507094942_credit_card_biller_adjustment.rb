class CreditCardBillerAdjustment < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :credit_card_bill_partners, throttler: throttler do |t|
      t.add_column :terms_and_conditions, :text
      t.add_column :biller_code, "VARCHAR(50) default null"
      t.add_column :bukalapak_admin_charge, :integer
      t.add_column :partner_admin_charge, :integer
      t.add_column :credit_card_biller_id, :integer
      t.add_column :state, "tinyint"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :credit_card_bill_partners, throttler: throttler do |t|
      t.remove_column :terms_and_conditions
      t.remove_column :biller_code
      t.remove_column :bukalapak_admin_charge
      t.remove_column :partner_admin_charge
      t.remove_column :credit_card_biller_id
      t.remove_column :state
    end
  end
end
