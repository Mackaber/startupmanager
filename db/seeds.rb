# encoding: utf-8
# populate box categories
if Box.all.empty?
  Box.create(:name => "key_partners",           :label => 'Aliados estrategicos')
  Box.create(:name => "key_activities",         :label => 'Actividades clave')
  Box.create(:name => "key_resources",          :label => 'Recursos Clave')
  Box.create(:name => "value_propositions",     :label => 'Propuesta de Valor')
  Box.create(:name => "customer_relationships", :label => 'Relaciones con los Clientes')
  Box.create(:name => "channels",               :label => 'Canales')
  Box.create(:name => "customer_segments",      :label => 'Segmentos de Clientes')
  Box.create(:name => "cost_structure",         :label => 'Estructura de Costos')
  Box.create(:name => "advantage",         :label => 'Ventaja competitiva')
  Box.create(:name => "key_metrics",         :label => 'Metricas clave')
  Box.create(:name => "solution",         :label => 'Solucion')
  Box.create(:name => "problems",         :label => 'Problemas')
end

if ItemStatus.all.empty?
  ItemStatus.create(:status => "unknown")
  ItemStatus.create(:status => "valid")
  ItemStatus.create(:status => "invalid")
  ItemStatus.create(:status => "started")
  ItemStatus.create(:status => "completed")
end