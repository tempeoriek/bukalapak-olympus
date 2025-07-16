class Keystore < ApplicationRecord
  include Postpaid::Constant

  validates :key, presence: true

  ALLOWED_KEYS = Set.new([
    'bni_access_token',
    Channel::Dji::BpjsKesehatan::REFERENCE_NUMBER_KEY,
    Channel::Dji::Pdam::REFERENCE_NUMBER_KEY,
    Channel::Dji::Base::SECURITY_NUMBER_KEY,
    Iso8583::Dji::UNIQUE_NUMBER_KEY,
    Channel::Bukopin::ElectricityPostpaid::Constants::BUKOPIN_ENCRYPT_KEY,
    Channel::Bukopin::ElectricityPostpaid::Constants::BUKOPIN_UNIQUE_NUMBER_KEY,
    Channel::Bukopin::ElectricityPostpaid::Constants::BUKOPIN_ENCRYPT_KEY_BMI,
    Channel::Bukopin::ElectricityPostpaid::Constants::BUKOPIN_UNIQUE_NUMBER_KEY_BMI,
    EMAIL_TELOLET_TOGGLE,
    ELECTRICITY_EMAIL_TELOLET_TOGGLE,
    BalanceTracker::ElectricityPostpaid::BUKALAPAK_BALANCE,
    BalanceTracker::ElectricityPostpaid::BUKALAPAK_THRESHOLD,
    BalanceTracker::ElectricityPostpaid::MITRA_BALANCE,
    BalanceTracker::ElectricityPostpaid::MITRA_THRESHOLD,
    Channel::NewBNI::Request::Base::NEW_BNI_ACCESS_TOKEN_KEY,
  ]).freeze

  class << self
    def get(key)
      raise Exceptions::KeyNotAllowed.new(key) unless ALLOWED_KEYS.include? key

      result = find_by_key(key)
      if result.nil? || (!result.expiration_time.nil? && result.expiration_time <= Time.now)
        return nil
      end

      result.value
    end

    def set(key, value = nil, seconds_expiration_time = nil)
      raise Exceptions::KeyNotAllowed.new(key) unless ALLOWED_KEYS.include? key

      store = find_or_initialize_by(key: key)
      store.value = value
      store.expiration_time = seconds_expiration_time.nil? ? nil : Time.new + seconds_expiration_time
      store.save!

      store
    end

    def del(key)
      set(key, nil, nil)
    end

    def expire(key)
      raise Exceptions::KeyNotAllowed.new(key) unless ALLOWED_KEYS.include? key

      result = find_by_key(key)
      result.value = nil
      result.expiration_time = nil
      result.save!

      result
    end

    def expireat(key, time)
      raise Exceptions::KeyNotAllowed.new(key) unless ALLOWED_KEYS.include? key

      result = find_by_key(key)
      result.update!(expiration_time: time)

      result
    end

    def increment(key)
      raise Exceptions::KeyNotAllowed.new(key) unless ALLOWED_KEYS.include? key

      result = find_or_initialize_by(key: key)

      if result.value.nil? || integer?(result.value)
        ActiveRecord::Base.transaction do
          result.lock!

          result.value = (result.value.to_i + 1).to_s
          result.save!
        end
      else
        raise Exceptions::NonIntegerValue.new
      end

      result.value.to_i
    end

    private

    # return the value if integer
    def integer?(obj)
      Integer obj rescue false
    end
  end
end
