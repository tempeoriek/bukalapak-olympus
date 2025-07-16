class CreateBpjsKesehatanPartner < ActiveRecord::Migration[5.1]
  def change
    create_table :bpjs_kesehatan_partners do |t|
      t.string  :name
      t.integer :partner_admin_charge
      t.integer :bukalapak_admin_charge
      t.integer :state

      t.timestamps
    end
  end
end
