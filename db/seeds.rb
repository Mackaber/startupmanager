# encoding: utf-8
# populate box categories
if Box.all.empty?
  Box.create(:name => "key_partners",           :label => 'Problema')
  Box.create(:name => "key_activities",         :label => 'Solución')
  Box.create(:name => "key_resources",          :label => 'Métricas Clave')
  Box.create(:name => "value_propositions",     :label => 'Propuesta Única de Valor')
  Box.create(:name => "customer_relationships", :label => 'Ventaja Competitiva')
  Box.create(:name => "channels",               :label => 'Canales')
  Box.create(:name => "customer_segments",      :label => 'Segmentos de Clientes')
  Box.create(:name => "cost_structure",         :label => 'Estructura de Costos')
  Box.create(:name => "revenue_stream",         :label => 'Flujo de Ingresos')
end

if ItemStatus.all.empty?
  ItemStatus.create(:status => "unknown")
  ItemStatus.create(:status => "valid")
  ItemStatus.create(:status => "invalid")
  ItemStatus.create(:status => "started")
  ItemStatus.create(:status => "completed")
end