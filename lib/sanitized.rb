# encoding: utf-8
module Sanitized
  
  def self.included(base)
    base.class_eval do
      cattr_accessor :to_sanitize
      @@sanitizer = ::HTML::WhiteListSanitizer.new
      base.to_sanitize = base.columns.select{|x| x.type == :text}.collect{|x| x.name}

      before_save do |rec|
        rec.class.to_sanitize.each do |col|
          if (rec.send("#{col}_changed?") && !rec.send(col).blank?)
            rec.sanitize(col)
          end 
        end
        true
      end
      
      def sanitize(col)
        self.send("#{col}=", @@sanitizer.sanitize(self.send(col)))
      end
    end
  end

end