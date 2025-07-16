class AddReferenceNumberToPhoneCreditTransaction < ActiveRecord::Migration[5.1]
  def change
    add_column :phone_credit_postpaid_transactions, :reference_number, :string
  end
end
