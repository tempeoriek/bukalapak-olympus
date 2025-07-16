class CreateElectricityPostpaidPartner < ActiveRecord::Migration[5.1]
  def self.up
    create_table :electricity_postpaid_partners do |t|
      t.string :name
      t.integer :partner_admin_charge
      t.integer :bukalapak_admin_charge
      t.integer :state

      t.timestamps
    end
  end

  def self.down
    drop_table :electricity_postpaid_partners
  end
end
