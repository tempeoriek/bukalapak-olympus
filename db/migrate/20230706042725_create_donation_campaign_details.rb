class CreateDonationCampaignDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :donation_campaign_details do |t|
      t.integer :donation_campaign_id
      t.string :image_url
      t.string :packet_name
      t.integer :nominal
      t.integer :quota, limit: 2
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end

    add_index :donation_campaign_details, [:deleted, :donation_campaign_id], name: :index_deleted_campaignid
  end
end
