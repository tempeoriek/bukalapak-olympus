WhitelistVisa = Set.new(ENV['WHITELIST_VISA']&.split(','))
WhitelistVisaPartnerIDs = Set.new(ENV['WHITELIST_VISA_PARTNER_IDS']&.split(',')).to_a
