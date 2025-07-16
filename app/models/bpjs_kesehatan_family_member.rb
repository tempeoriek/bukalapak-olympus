class BpjsKesehatanFamilyMember < ApplicationRecord
  belongs_to :bpjs_kesehatan_transaction

  def as_json(_options={})
    super(
      only: [
        :id,
        :member_number,
        :name,
        :premium,
        :balance
      ]
    )
  end
end
