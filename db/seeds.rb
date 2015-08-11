#populate box categories
if Box.all.empty?
  Box.create(:name => "key_partners",           :label => 'Key Partners')
  Box.create(:name => "key_activities",         :label => 'Key Activities')
  Box.create(:name => "key_resources",          :label => 'Key Resources')
  Box.create(:name => "value_propositions",     :label => 'Value Propositions')
  Box.create(:name => "customer_relationships", :label => 'Cust. Relationships')
  Box.create(:name => "channels",               :label => 'Channels')
  Box.create(:name => "customer_segments",      :label => 'Cust. Segments')
  Box.create(:name => "cost_structure",         :label => 'Cost Structure')
  Box.create(:name => "revenue_stream",         :label => 'Revenue Stream')
end

if ItemStatus.all.empty?
  ItemStatus.create(:status => "unknown")
  ItemStatus.create(:status => "valid")
  ItemStatus.create(:status => "invalid")
  ItemStatus.create(:status => "started")
  ItemStatus.create(:status => "completed")
end