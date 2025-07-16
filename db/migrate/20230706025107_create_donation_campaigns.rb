class CreateDonationCampaigns < ActiveRecord::Migration[5.2]
  def change
    create_table :donation_campaigns do |t|
      t.integer :foundation_id
      t.string :title, null: false, limit: 50
      t.string :short_description
      t.text :description, null: false
      t.string :slug, unique: true
      t.string :image_url, null: false
      t.string :story_image_url
      t.string :thumbnail_url
      t.integer :campaign_type, null: false, limit: 1
      t.boolean :banner_showed, default: true
      t.string :url
      t.string :location_text
      t.datetime :campaign_due
      t.string :other_donation_url
      t.string :brand_parameterized_name
      t.string :banners_url, limit: 1000
      t.datetime :start_time
      t.datetime :end_time
      t.decimal :donation_min, precision: 12, scale: 2
      t.decimal :donation_max, precision: 15, scale: 2
      t.integer :bl_total_donor
      t.integer :all_total_donor
      t.decimal :target_expense, precision: 15, scale: 2
      t.decimal :bl_collected_expense, precision: 15, scale: 2
      t.decimal :all_collected_expense, precision: 15, scale: 2
      t.string :available_nominals, limit: 50
      t.integer :extra_percentage, default: 0
      t.integer :extra_maximum_amount, default: 0
      t.integer :extra_budget, default: 0
      t.integer :deduction_percentage, default: 0
      t.integer :flow_type, null: false, limit: 1, default: 1
      t.boolean :partnering, null: false, default: false
      t.integer :partner_id
      t.boolean :keep_update, null: false, default: true
      t.datetime :partner_updated_at
      t.integer :sort_order, null: false, default: 99
      t.integer :custom_sort_order, default: 99
      t.boolean :visibility, null: false, default: true
      t.boolean :active, null: false, default: true
      t.integer :updater_id
      t.boolean :deleted, null: false, default: false
      t.string :partner, limit: 25
      t.integer :category_id

      t.timestamps
    end

    add_index :donation_campaigns, :slug, unique: true
    add_index :donation_campaigns, [:deleted, :active, :visibility, :foundation_id, :sort_order], name: :index_deleted_active_visibility_foundation_sortorder
    add_index :donation_campaigns, [:deleted, :active, :slug], name: :index_deleted_active_slug
    add_index :donation_campaigns, :custom_sort_order, name: :custom_sort_order
    add_index :donation_campaigns, :start_time, name: :index_start_time
    add_index :donation_campaigns, :end_time, name: :index_end_time
  end
end
