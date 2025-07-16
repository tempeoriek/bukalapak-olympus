class CreateMultifinanceBillers < ActiveRecord::Migration[5.1]
  def change
    create_table :multifinance_billers do |t|
      t.string    :name
      t.string    :code
      t.string    :image_url, null: true
      t.integer   :bukalapak_admin_charge
      t.integer   :partner_admin_charge
      t.integer   :active, default: 0
      t.integer   :partner, default: 0

      t.timestamps
    end
  end
end
