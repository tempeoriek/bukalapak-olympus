class AddPartnerToPhoneCreditPostpaidTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :phone_credit_postpaid_transactions, :partner, :integer
  end
end
