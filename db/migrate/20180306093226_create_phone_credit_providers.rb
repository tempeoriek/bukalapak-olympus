class CreatePhoneCreditProviders < ActiveRecord::Migration[5.1]
  def change
    create_table :phone_credit_providers do |t|
      t.string :provider
      t.string :product_name
      t.string :logo_url
      t.string :partner_product_id
      t.integer :partner
      t.integer :partner_admin_charge
      t.integer :bukalapak_admin_charge
      t.integer :active
      t.timestamps
      t.datetime :activated_at, null: true
      t.datetime :inactivated_at, null: true
    end

    add_index :phone_credit_providers, :created_at
    add_index :phone_credit_providers, :updated_at
    add_index :phone_credit_providers, :active
  end
end
