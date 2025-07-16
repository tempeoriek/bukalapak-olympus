module ApplicationHelper
  include ActionView::Helpers::NumberHelper

  def money(number)
    currency = ''
    while (number / 1000 > 0) do
      mod_number = "%03d" %(number%1000)
      currency = ".#{mod_number}#{currency}"
      number /= 1000
    end
    currency = "Rp#{number}#{currency}"
    return currency
  end

  # TODO: refactor `recurrent?` to be a model method instead: `transaction.recurrent?`
  def recurrent?(transaction)
    transaction.respond_to?(:template_detail_id) && !transaction.template_detail_id.nil?
  end

  def get_censored_phone_number(phone_number, options={})
    revealed_prefix_digits = options[:revealed_prefix_digits] || 3
    revealed_suffix_digits = options[:revealed_prefix_digits] || 3
    censored_digits = phone_number.length - (revealed_prefix_digits + revealed_suffix_digits)

    phone_number[revealed_prefix_digits, censored_digits] = 'x' * censored_digits
    phone_number
  end

  def snake_case(string)
    string = string.gsub(/[.]/, '')
    string = string.gsub(/[\s]/, '_')
    string = string.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    string = string.gsub(/([a-z\d])([A-Z])/,'\1_\2')
    string = string.tr("-", "_")
    string.downcase
  end
end
