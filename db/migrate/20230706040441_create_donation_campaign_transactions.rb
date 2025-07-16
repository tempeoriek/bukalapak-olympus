class CreateDonationCampaignTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :donation_campaign_transactions do |t|
      t.integer :donation_campaign_id
      t.integer :donor_id
      t.bigint  :invoice_id
      t.bigint  :remote_id
      t.integer :remote_partner_id
      t.integer :state, limit: 1
      t.decimal :nominal, precision: 15, scale: 2
      t.integer :extra_amount, default: 0
      t.boolean :anonymous, null: false, default: true
      t.decimal :nominal_fee, precision: 12, scale: 2
      t.string :source, default: "donation_adhoc"
      t.datetime :processed_at
      t.datetime :succeeded_at
      t.datetime :failed_at
      t.datetime :expired_at
      t.integer :updater

      t.timestamps
    end

    add_index :donation_campaign_transactions, :donor_id, name: :index_donorid
    add_index :donation_campaign_transactions, :invoice_id, name: :index_invoiceid
    add_index :donation_campaign_transactions, :remote_id, name: :index_remoteid
    add_index :donation_campaign_transactions, :donation_campaign_id, name: :index_donation_campaign_id
  end
end
