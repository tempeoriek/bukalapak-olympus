class CreateZakatCampaigns < ActiveRecord::Migration[5.2]
  def self.up
    create_table :zakat_campaigns do |t|
      t.string "image_url", null: false
      t.string "title", null: false
      t.text "description"
      t.string "slug", null: false
      t.integer "foundation_id"
      t.boolean "active", default: true
      t.boolean "deleted", default: false
      t.timestamps
    end

    add_index :zakat_campaigns, [:active, :slug]
  end

  def self.down
    drop_table :zakat_campaigns
  end
end
