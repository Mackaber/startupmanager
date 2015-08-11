module ActiveRecord
  
  class Base
    
    def write_attribute_with_stripper(attr_name, value)
      column = column_for_attribute(attr_name)
      if (column && column.type != :binary)
        value = value.strip if value.respond_to?(:strip)
        value = nil if value.respond_to?(:empty?) && value.empty? && value != column.default
      end
      write_attribute_without_stripper(attr_name, value)
    end

    alias_method_chain :write_attribute, :stripper
    
  end
  
end
