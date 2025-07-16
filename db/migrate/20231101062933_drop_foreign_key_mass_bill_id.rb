class DropForeignKeyMassBillId < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :electricity_postpaid_mass_bills, column: :postpaid_transaction_id
  end
end
