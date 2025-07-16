class CreateCreditCardBillPartner < ActiveRecord::Migration[5.1]
  def change
    create_table :credit_card_bill_partners do |t|
      t.string  :name
    end
  end
end
