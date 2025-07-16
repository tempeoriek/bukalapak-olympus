module BpjsKetenagakerjaanHelper
  def self.mask_name(name)
    masked_name = name.split.map do |word|
      if word.length <= 3
        word
      else
        first_two_chars = word[0..1]
        last_char = word[-1]
        masked_chars = "*" * (word.length - 3)
        first_two_chars + masked_chars + last_char
      end
    end

    masked_name.join(" ")
  end
end
