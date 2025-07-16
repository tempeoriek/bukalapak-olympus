module Config
  class Base
    def self.config(default={})
      NeoClient::Search.config(config_name).data
    rescue StandardError => e
      default
    end

    def self.description
      raise NotImplementedError
    end

    def self.config_name
      raise NotImplementedError
    end
  end
end
