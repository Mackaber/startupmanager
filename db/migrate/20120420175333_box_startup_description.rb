class BoxStartupDescription < ActiveRecord::Migration
  def up
    add_column "boxes", "startup_description", :text
    Box.reset_column_information
    
    [
      ["customer_segments", "List your target customers and users"],
      ["value_propositions", "A concise statement that describes why customers will fall in love with your product"],
      ["channels", "The ways you will reach your customers"],
      ["customer_relationships", "What do you have that your competitors don't?"],
      ["revenue_stream", "List your sources of revenue"],
      ["key_resources", "List the metrics that will tell you the health of your business"],
      ["key_activities", "List a solution for each problem"],
      ["key_partners", "List the problems that you are trying to solve"],
      ["cost_structure", "List all of the costs associated with your business"],
    ].each do |name, description|
      Box.find_by_name(name).update_attributes!(:startup_description => description)
    end
  end

  def down
  end
end
