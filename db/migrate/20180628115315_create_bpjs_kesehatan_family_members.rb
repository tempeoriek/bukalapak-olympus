class CreateBpjsKesehatanFamilyMembers < ActiveRecord::Migration[5.1]
  def change
    create_table :bpjs_kesehatan_family_members do |t|
      t.string  :member_number
      t.string  :name
      t.integer :premium
      t.integer :balance
      t.integer :bpjs_kesehatan_transaction_id

      t.timestamps
    end

    add_index :bpjs_kesehatan_family_members, :bpjs_kesehatan_transaction_id, :name => 'index_bpjs_kesehatan_family_members_on_bpjs_kesehatan_id'
  end
end
