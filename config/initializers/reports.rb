if Rails.env.development?
  Dir["#{Rails.root.to_s}/app/models/reports/*.rb"].each do |file|
    load file
  end
end