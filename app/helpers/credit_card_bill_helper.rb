module CreditCardBillHelper
  def masking(result, biller_code)
    card = result.customer_number
    card = card[0..5]+("X"*(card.length-10))+card[-4..-1]
    masked_card = ""
    if biller_code == "AMEX"
      masked_card = "#{card[0..3]}-#{card[4..9]}-#{card[-5..-1]}"
    else
      while card.length > 0 do
        if card.length > 4
          masked_card = "#{masked_card}-#{card[0..3]}"
          card = card[4..-1]
        else
          masked_card = "#{masked_card}-#{card[0..-1]}"
          card = ""
        end
      end
      masked_card = masked_card[1..-1]
    end

    result.customer_number = "C" + result.customer_number if result.customer_number.length % 2 == 1
    result.card_data = result.customer_number
    result.customer_number = masked_card
    result
  end

  def self.mask_name(name, mask_char='X')
    def self.mask_name_with_offset(name, offset_left, offset_right, mask_char)
      mask_digits = (name.length - (offset_left + offset_right))
      mask_string = mask_digits < 0 ? '' : mask_char * mask_digits
      return name[0..offset_left-1] + mask_string + name[name.length-offset_right..name.length]
    end

    if name.is_a?(String)
      offset = 3; threshold = 9
      if name.length < threshold
        offset_left = 3; offset_right = 0
      else
        offset_left = 3; offset_right = 3
      end

      mask_name_with_offset(name, offset_left, offset_right, mask_char)
    else
      nil
    end
  end

  def self.crypto_hash_cc_number(cc_number)
    salt = ENV['HASH_SALT_CC_NUMBER']
    hashed = RbNaCl::Hash.sha256("#{salt}-#{cc_number}").unpack('H*').first
    hashed
  end

  def self.crypto_hash_in_object(obj, key_names)
    return nil if obj.nil?
    key_names.each do |key|
      obj[key] = crypto_hash_cc_number(obj[key]) unless obj[key].nil?
    end
  rescue
    nil
  end

  def self.hash_cc_number_in_object(obj = {}, cc_number_key_names = [])
    return nil if !Toggles::CryptoHashSensitiveData.active? || !obj.is_a?(Hash)

    obj.deep_symbolize_keys!

    # root
    crypto_hash_in_object(obj, cc_number_key_names)

    # object that has attribute "data"
    unless obj[:data].nil?
      crypto_hash_in_object(obj[:data], cc_number_key_names)

      # /_internal/dbs/inquiry-transaction
      crypto_hash_in_object(obj[:data][:receiving_party], cc_number_key_names)
    end

    # /_internal/dbs/payment
    if !obj[:payments].nil? && obj[:payments].is_a?(Array)
      obj[:payments].each do |payment|
        crypto_hash_in_object(payment[:receiver], cc_number_key_names)
      end
    end
  end

  def self.sha256_digest(data)
    RbNaCl::Hash.sha256(data)
  end

  def self.hmac_sha256_digest(data, key) # key must be 32 char binary encoded
    digest = RbNaCl::HMAC::SHA256.new(key).auth(data)
    Base64.strict_encode64(digest)
  end
end
