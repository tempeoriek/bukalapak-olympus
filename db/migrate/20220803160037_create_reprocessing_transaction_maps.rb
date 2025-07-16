class CreateReprocessingTransactionMaps < ActiveRecord::Migration[5.2]
  def change
    create_table :reprocessing_transaction_maps do |t|
      t.bigint :job_id
      t.bigint :transaction_id

      t.timestamps
    end
    add_index :reprocessing_transaction_maps, :job_id
    add_index :reprocessing_transaction_maps, :transaction_id
  end
end
