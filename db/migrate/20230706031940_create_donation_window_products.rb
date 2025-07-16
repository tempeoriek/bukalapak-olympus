class CreateDonationWindowProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :donation_window_products do |t|
      t.integer :donation_window_id
      t.string :product_id
      t.integer :sort_order, limit: 2
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end

    add_index :donation_window_products, [:deleted, :donation_window_id, :sort_order], name: :index_deleted_donationwindow_sortorder
  end
end
