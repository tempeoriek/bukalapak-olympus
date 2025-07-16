class CreateBrandPartners < ActiveRecord::Migration[5.2]
  def change
    create_table :brand_partners do |t|
      t.string :parameterized_name
      t.integer :user_id
      t.string :username
      t.string :brand_name
      t.text :brand_description
      t.text :page_description
      t.string :url
      t.string :logo_url
      t.string :background_desktop_url
      t.string :background_mobile_url
      t.boolean :promoted
      t.integer :promoted_product_counter
      t.boolean :local_brand
      t.datetime :brand_created_at
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :brand_partners, [:user_id], name: :index_userid
    add_index :brand_partners, [:username], name: :index_username
    add_index :brand_partners, [:parameterized_name], name: :index_parameterized
    add_index :brand_partners, [:parameterized_name], unique: true, name: :index_brand_partners_on_parameterized_name
  end
end
