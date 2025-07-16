class CreateProviderPrefixes < ActiveRecord::Migration[5.1]
  def change
    create_table :provider_prefixes do |t|
      t.string :prefix
      t.bigint :provider_id

      t.timestamps
    end

    add_index :provider_prefixes, :created_at
    add_index :provider_prefixes, :updated_at
  end
end
