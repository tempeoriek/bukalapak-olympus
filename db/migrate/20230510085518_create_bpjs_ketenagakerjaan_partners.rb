class CreateBpjsKetenagakerjaanPartners < ActiveRecord::Migration[5.2]
  def change
    create_table :bpjs_ketenagakerjaan_partners do |t|
      t.string    :name
      t.integer   :partner_admin_charge, default: 0, unsigned: true
      t.integer   :bukalapak_admin_charge, default: 0, unsigned: true
      t.integer   :state
      t.datetime  :created_at, null: false
      t.datetime  :updated_at, null: false
      t.integer   :revenue

      t.timestamps
    end
  end
end
