class CreateBpjsKetenagakerjaanBills < ActiveRecord::Migration[5.2]
  def change
    create_table :bpjs_ketenagakerjaan_bills do |t|
      t.integer :jkk, default: 0, unsigned: true
      t.integer :jkm, default: 0, unsigned: true
      t.integer :jht, default: 0, unsigned: true
      t.integer :jpk, default: 0, unsigned: true
      t.integer :jpn, default: 0, unsigned: true
      t.integer :amount, default: 0, unsigned: true
      t.bigint :bpjs_ketenagakerjaan_transaction_id

      t.timestamps
    end
  end
end
