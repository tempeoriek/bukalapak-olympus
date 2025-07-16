class CreateElectricityPostpaidMassBills < ActiveRecord::Migration[5.2]
  def change
    create_table :electricity_postpaid_mass_bills do |t|
      t.string :mass_bill_id, limit: 36
      t.belongs_to :postpaid_transaction, foreign_key: true, index: { unique: true }

      t.timestamps
    end

    add_index :electricity_postpaid_mass_bills, [:mass_bill_id, :postpaid_transaction_id], unique: true, name: "index_elec_postpaid_mass_bill_unique"
  end
end
