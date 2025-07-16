class CreateFoundationProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :foundation_products do |t|
      t.integer :foundation_id
      t.string :product_id
      t.boolean :active, null: false, default: true
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end

    add_index :foundation_products, :foundation_id
  end
end
