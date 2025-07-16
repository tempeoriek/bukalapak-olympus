PdamOperator.find_each do |operator|
  operator.partner = "sepulsa"
  operator.save!
end
