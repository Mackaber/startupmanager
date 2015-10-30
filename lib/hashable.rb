# encoding: utf-8
module Hashable
  
  def to_hash(include_fields, omit_fields)
    h = {:type => self.class.name.underscore, :id => self.id}
    h.instance_variable_set(:@include_fields, include_fields)
    h.instance_variable_set(:@omit_fields, omit_fields)
    
    class <<h
      def add_field(key, value)
        if ((@include_fields.nil? || @include_fields.include?(key)) && (@omit_fields.nil? || !@omit_fields.include?(key)))
          v = (value.is_a?(Proc) ? value.yield : value)
          self[key] = v unless v.nil?
        end
      end      
    end
    
    return h
  end

end