require "resque_scheduler"
#Resque.redis = YAML.load_file(File.expand_path('../../resque.yml', __FILE__))[ENV['RAILS_ENV'] || ENV['RACK_ENV'] || Rails.env]
Resque.redis = REDIS
Resque.schedule = YAML.load_file(File.expand_path('../../resque_schedule.yml', __FILE__))
