class CreateDonationWindows < ActiveRecord::Migration[5.2]
  def change
    create_table :donation_windows do |t|
      t.string :label, null: false, limit: 25
      t.string :background_image_url, null: false
      t.string :banner_url
      t.integer :sort_order, null: false, default: 99
      t.boolean :active, null: false, default: true
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end

    add_index :donation_windows, [:deleted, :active, :sort_order], name: :index_deleted_active_sortorder
  end
end
