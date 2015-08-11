class Promotion < ActiveRecord::Base
  
  validates_presence_of :name
  
  LETTERS_AND_NUMBERS = ('A'..'Z').to_a + ("0".."9").to_a
  
  before_create do |promotion|
    while (promotion.code.nil? || Promotion.find_by_code(promotion.code))
      promotion.code = (1..9).collect { LETTERS_AND_NUMBERS[rand 36] }.join
    end
  end
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/json") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :name => self.name,
        :monthly_discount_percent => self.monthly_discount_percent,
        :months => self.months
      }
    end
  end
  
end