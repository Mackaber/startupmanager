class BoxDescriptions < ActiveRecord::Migration
  def up
    [
      ["customer_segments", "Which groups of people or organizations are you trying to serve?"],
      ["value_propositions", "What value are you delivering?  What problems are you solving for your customers?"],
      ["channels", "How will your product be distributed and sold?"],
      ["customer_relationships", "How will you create demand for your product, retain existing customers, and grow your customer base?"],
      ["revenue_stream", "The cash you generate from each customer segment."],
      ["key_resources", "What assets do you need to make your business model work? These assets can be physical, financial, intellectual, or human."],
      ["key_activities", "What do you need to do in order to deliver your Value Proposition?"],
      ["key_partners", "What partnerships do you need to reach customers or deliver a Value Proposition?"],
      ["cost_structure", "List all of the costs incurred by your business."],
    ].each do |name, description|
      Box.find_or_create_by_name(name, :label => name.humanize, :startup_label => name.humanize).update_attributes!(:description => description)
    end
  end

  def down
  end
end
