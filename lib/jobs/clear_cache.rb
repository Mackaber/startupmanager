class Jobs::ClearCache < Jobs::Job      
  def self.run
    Rails.cache.clear
  end
end
