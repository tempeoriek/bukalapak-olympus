class CreateCreditCardBiller < ActiveRecord::Migration[5.1]
  def change
    create_table :credit_card_billers do |t|
    	t.string    :name
      t.string    :code
      t.string    :image_url, null: true
      t.text      :terms_and_conditions, null: true
      t.integer   :bukalapak_admin_charge
      t.integer   :partner_admin_charge
      t.integer   :active, default: 0
      t.integer   :credit_card_bill_partner_id

      t.timestamps
    end
  end
end
