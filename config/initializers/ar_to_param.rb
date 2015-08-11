module ActiveRecord
  
  class Base
    
    def to_param
      if new_record?
        return nil
      else
        return "#{id}-#{(to_s || '').normalize}"
      end
    end
    
  end
  
end
