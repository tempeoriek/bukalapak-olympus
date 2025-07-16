class CreateDonationFoundations < ActiveRecord::Migration[5.2]
  def change
    create_table :donation_foundations do |t|
      t.integer :user_id
      t.string :parameterized_name
      t.integer :total_campaign, limit: 2
      t.integer :sort_order, limit: 2
      t.boolean :active, null: false, default: true
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end

    add_index :donation_foundations, [:deleted, :active, :sort_order], name: :index_deleted_active_sortorder
  end
end
