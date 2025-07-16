# frozen_string_literal: true

module Toggles
  class Base
    include Toggleable::Base
  end

  class EmailNotif < Base
    def self.description
      'Toggle For Email Notif Feature'
    end
  end

  class Mws < Base
    def self.description
      'Toggle for Olympus MWS, otherwise RabbitMQ'
    end
  end

  class OlympusSievexPredict < Base
    def self.description
      'Toggle for SieveX, to check transaction status(NORMAL|FRAUD) from sievex rule'
    end
  end

  class OlympusSievexSend < Base
    def self.description
      'Toggle for SieveX, to sent transaction data'
    end
  end

  class OnSiteNotif < Base
    def self.description
      'Toggle For On Site Notif Feature'
    end
  end

  class PushNotif < Base
    def self.description
      'Toggle For Push Notif Feature'
    end
  end

  class WhitelistBukopin < Base
    def self.description
      'Toggle For Whitelist Bukopin Electricity Postpaid Feature'
    end
  end

  class WhitelistAyoConnect < Base
    def self.description
      'Toggle For Whitelist AyoConnect Electricity Postpaid Feature'
    end
  end

  class WhitelistTektaya < Base
    def self.description
      'Toggle For Whitelist Tektaya Electricity Postpaid Feature'
    end
  end

  class WhitleistPdamAllOperator < Base
    def self.description
      'Toggle for whitelist all operator PDAM'
    end
  end

  class CryptoHashSensitiveData < Base
    def self.description
      'Toggle for crypto-hashing sensitive data in logger'
    end
  end

  class WhitelistBni < Base
    def self.description
      'Toggle For Whitelist partner BNI'
    end
  end

  class WhitelistVisa < Base
    def self.description
      'Toggle For Whitelist partner Visa'
    end
  end

  class OlympusSievexAction < Base
    def self.description
      'Toggle for Sievex, to take action or not'
    end
  end

  class Pubsub < Base
    def self.description
      'Toggle for Pubsub, alternative for mws/rabbit'
    end
  end

  class CreditCardBill < Base
    def self.description
      'Toggle For Credit Card Bill Feature'
    end
  end

  class DjiCircuitBreaker < Base
    def self.description
      'Toggle Circuit breaker dji'
    end
  end

  class SepulsaMitraAuth < Base
    def self.description
      'Toggle Different AUTH for mitra buyer type'
    end
  end

  class BukopinMitraAuth < Base
    def self.description
      'Toggle Different AUTH for bukopin mitra buyer type'
    end
  end

  class PhoneCreditPostpaidMitraAuth < Base
    def self.description
      'Toggle Different AUTH for phone credit postpaid mitra buyer type'
    end
  end

  class PnlMitraAuth < Base
    def self.description
      'Toggle Different AUTH for pnl mitra & collecting_agent buyer type'
    end
  end

  class ElectricityPostpaidInternalUsePartner < Base
    def self.description
      'Toggle to enable the internal endpoints of electricity postpaid to receive partner'
    end
  end

  class BpjsKetenagakerjaanAyoconnectMock < Base
    def self.description
      'Toggle to enable mocking of BPJS Ketenagakerjaan Ayoconnect endpoints'
    end
  end
end
