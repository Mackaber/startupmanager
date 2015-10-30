# encoding: utf-8
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake/dsl_definition'
require 'rake'

LeanLaunchLab::Application.load_tasks

begin #metricFu not available on production 
  require 'metric_fu'
  MetricFu::Configuration.run do |config|
    config.metrics -= [:rcov]
    #config.metrics -= [:reek]
    #config.metrics -= [:flay]
    #config.metrics -= [:flog]
  end
rescue LoadError
end

require 'resque/tasks'
require 'resque_scheduler/tasks'  

# http://stackoverflow.com/questions/6137570/resque-enqueue-failing-on-second-run
task "resque:setup" => :environment do
  Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
end
  
task 'db:migrate' do
  Rake::Task['db:seed'].invoke
end

task 'db:schema:load' do
  Rake::Task['db:seed'].invoke
end

task 'ts:index' do
  puts "Clearing cache"
  Rails.cache.clear
end