class CreateDonationCampaignTransactionDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :donation_campaign_transaction_details do |t|
      t.integer :donation_campaign_transaction_id
      t.integer :donation_campaign_detail_id
      t.integer :donation_campaign_id
      t.integer :qty
      t.integer :nominal_per_qty

      t.timestamps
    end

    add_index :donation_campaign_transaction_details, :donation_campaign_transaction_id, name: :index_donation_campaign_transaction
    add_index :donation_campaign_transaction_details, :donation_campaign_id, name: :index_donation_campaign
    add_index :donation_campaign_transaction_details, :donation_campaign_detail_id, name: :index_donation_campaign_detail
  end
end
