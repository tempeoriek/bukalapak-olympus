module Converter
  class StringToDate
    include Postpaid::Constant

    # How to use
    # Converter::StringToDate.convert("20160723"), using default format
    # Converter::StringToDate.convert("201607", string_format: "yyyymm"), custom format
    def self.convert(string_date, string_format: YYYYMMDD)
      case string_format
      when YYYYMMDD
        year_month_and_date(string_date)
      when DDMMYYYY
        date_month_and_year(string_date)
      when YYYYMM
        year_and_month(string_date)
      when MMMYYYY
        month_and_full_year(string_date)
      when DDMMMYYYY
        day_abr_month_and_full_year(string_date)
      when MMMYY
        month_and_half_year(string_date)
      else
        raise "unsupported format"
      end
    end

    # this for format "yyyymmdd"
    def self.year_month_and_date(string)
      begin
        return nil unless numeric?(string) && string.length == 8
        year = string.slice(0..3).to_i
        month = string.slice(4..5).to_i
        day = string.slice(6..7).to_i
        Date.new(year, month, day)
      rescue ArgumentError => e
        # inverts to DDMMYYYY
        day = string.slice(0..1).to_i
        month = string.slice(2..3).to_i
        year = string.slice(4..7).to_i
        Date.new(year, month, day)
      end
    end

    # this for format "ddmmyyyy"
    def self.date_month_and_year(string)
      return nil unless numeric?(string) && string.length == 8
      day = string.slice(0..1).to_i
      month = string.slice(2..3).to_i
      year = string.slice(4..7).to_i
      Date.new(year, month, day)
    end

    # this for format "yyyymm"
    def self.year_and_month(string)
      return nil unless numeric?(string) && string.length == 6
      year = string.slice(0..3).to_i
      month = string.slice(4..5).to_i
      Date.new(year, month).beginning_of_month
    end

    # this for format "MMMyyyy"
    # Example: "Jan2016", "Feb2021", "May2018"
    def self.month_and_full_year(string)
      return nil unless string.is_a?(String) && string.length == 7
      month = MONTH_MAP[string.slice(0..2).upcase].to_i
      year = string.slice(3..-1).to_i
      Date.new(year, month).beginning_of_month
    end

    # this for format "ddMMMyyyy"
    # Example: "21-JAN-2016", "21-FEB-2021", "21-AGU-2018"
    def self.day_abr_month_and_full_year(string)
      return nil unless string.is_a?(String) && string.length == 11
      day = string.slice(0..1).to_i
      month = MONTH_MAP[string.slice(3..5).upcase].to_i
      year = string.slice(7..-1).to_i
      Date.new(year, month, day)
    end

    # this for format "MMMyy"
    # Example: "Jan16", "Feb21", "May18"
    def self.month_and_half_year(string)
      return nil unless string.is_a?(String) && string.length == 5
      month = MONTH_MAP[string.slice(0..2).upcase].to_i
      year = string.slice(3..-1).to_i

      return nil if year > 100 || month == 0
      year += 2000 # Adjust for two-digit year format
      Date.new(year, month).beginning_of_month
    end

    def self.numeric?(string)
      true if Float(string) rescue false
    end

    private_class_method :year_month_and_date, :year_and_month, :numeric?
  end
end
