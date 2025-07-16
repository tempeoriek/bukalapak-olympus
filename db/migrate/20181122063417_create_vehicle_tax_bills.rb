class CreateVehicleTaxBills < ActiveRecord::Migration[5.1]
  def change
    create_table :vehicle_tax_bills do |t|
      t.string    :code
      t.integer   :buyer_id
      t.integer   :transaction_id, unsigned: true
      t.integer   :amount
      t.integer   :fee
      t.string    :customer_number
      t.string    :customer_name
      t.text      :customer_address
      t.string    :engine_number
      t.string    :structure_number
      t.string    :license_plate
      t.string    :vehicle_brand
      t.string    :vehicle_model
      t.string    :vehicle_color
      t.string    :year_built
      t.date      :tax_expired_date
      t.date      :stnk_expired_date
      t.integer   :amount_bnn, default: 0
      t.integer   :amount_pkb, default: 0
      t.integer   :amount_swd, default: 0
      t.integer   :penalty_bnn, default: 0
      t.integer   :penalty_pkb, default: 0
      t.integer   :penalty_swd, default: 0
      t.integer   :fee_stnk, default: 0
      t.integer   :fee_tnkb, default: 0

      t.timestamps
    end

    add_index :vehicle_tax_bills, :code
    add_index :vehicle_tax_bills, [:buyer_id, :code, :transaction_id]
    add_index :vehicle_tax_bills, [:transaction_id, :structure_number]
  end
end
