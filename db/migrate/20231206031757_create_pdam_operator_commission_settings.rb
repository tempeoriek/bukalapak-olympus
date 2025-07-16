class CreatePdamOperatorCommissionSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :pdam_operator_commission_settings do |t|
      t.integer :value 
      t.integer :min_transaction_value
      t.integer :max_transaction_value 
      t.belongs_to :pdam_operator, index: { name: 'pdam_operator_commission_settings_pdam_operator_idx' }

      t.timestamps
    end
  end
end
