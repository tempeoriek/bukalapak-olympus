class CreateDonationServices < ActiveRecord::Migration[5.2]
  def change
    create_table :donation_services do |t|
      t.integer :foundation_id
      t.string :service_code, null: false, limit: 25
      t.string :service_name, null: false, limit: 25
      t.string :service_image, null: false
      t.string :service_url, null: false
      t.integer :sort_order, null: false, default: 99
      t.boolean :active, null: false, default: true
      t.boolean :deleted, null: false, default: false
      t.boolean :is_master, default: false

      t.timestamps
    end

    add_index :donation_services, [:deleted, :active, :sort_order], :name => 'index_deleted_active_sortorder'
    add_index :donation_services, :is_master
    add_index :donation_services, :foundation_id
  end
end
