class PdamOperator < ApplicationRecord
  include Postpaid::Constant

  enum partner: {
    sepulsa: 0,
    dji: 1,
    vsi_thor: 3,
    mkm_thor: 4,
    fortuna_thor: 5,
    bms_thor: 6
  }

  enum active: {
    deleted: -1,
    inactive: 0,
    active: 1
  }

  enum have_issue: {
    false: 0,
    true: 1
  }

  scope :not_deleted, -> { where(:active => [INACTIVE, ACTIVE]) }

  def as_json(_options={})
    super(
      only: [
        :id,
        :name,
        :group,
        :image_url,
        :terms_and_conditions,
        :have_issue,
        :update_selling_price
      ]
    )
  end

  def admin_charge
    bukalapak_admin_charge + partner_admin_charge
  end

  def self.whitelist_operator(username)
    whitelist_username = WhitelistPdamUsername.include?(username)

    return PdamOperator.where(active: true) if whitelist_username == true || Toggles::WhitleistPdamAllOperator.active?

    if Toggle::PdamAutoswitch.active?
      operators = PdamOperator.where("id IN (?) AND code NOT IN (?) AND active = TRUE", PdamAutoswitchGroupMember.where(state: 'active').pluck(:operator_id), Array(WhitelistPdamOperatorCodes))
    else
      operators = PdamOperator.where("code NOT IN (?) AND active = TRUE",  Array(WhitelistPdamOperatorCodes))
    end

    return operators
  end

  def have_issue?
    self.have_issue.downcase == 'true'
  end
end
