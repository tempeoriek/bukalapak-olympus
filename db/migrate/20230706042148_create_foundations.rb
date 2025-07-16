class CreateFoundations < ActiveRecord::Migration[5.2]
  def change
    create_table :foundations do |t|
      t.integer :user_id
      t.string :name
      t.string :parameterized_name
      t.string :slug
      t.string :banner_url_desktop
      t.string :banner_url_app
      t.string :icon_url
      t.text :description
      t.string :address
      t.string :website_url
      t.string :facebook_url
      t.string :twitter_url
      t.string :instagram_url
      t.integer :active_event_id
      t.integer :event_id
      t.integer :updater_id
      t.integer :sort_order, null: false, default: 99
      t.boolean :active, null: false, default: true
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
  end
end
