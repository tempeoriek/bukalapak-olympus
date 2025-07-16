PdamOperator.find_each do |operator|
  if operator.partner == 'sepulsa'
    operator.bukalapak_admin_charge = 1450
    operator.partner_admin_charge = 550
    operator.save!
  end
end
