class BoxStartupDescriptionChange < ActiveRecord::Migration
  def up
    Box.reset_column_information
    [
        ["customer_segments", "tu mercado meta y primeros clientes", "segmentos de mercado", "segmentos de mercado"],
        ["value_propositions", "una oracion de porque los clientes deben amar tu producto", "propuesta unica de valor", "propuesta unica de valor"],
        ["channels", "la forma en que llegaras a tus clientes", "canales", "canales"],
        ["customer_relationships", "que tienes tu que tus competidores no?", "ventaja competitiva", "ventaja competitiva"],
        ["revenue_stream", "lista de las formas en que tienes ingresos", "flujo de ingreso", "flujo de ingreso"],
        ["key_resources", "lista de las metricas que indican progreso en el negocio", "metricas clave", "metricas clave"],
        ["key_activities", "lista de las soluciones de cada problema", "soluciones", "soluciones"],
        ["key_partners", "lista de los problemas que tratas de resolver", "problemas", "problemas"],
        ["cost_structure", "lista de todos los costos asociados con tu negocio", "estructura de costos", "estructura de costos"],
    ].each do |name, description, label, startuplabel|
      Box.find_by_name(name).update_attributes!(:startup_description => description, :label => label, :startup_label => startuplabel )
    end
  end

  def down
  end
end
