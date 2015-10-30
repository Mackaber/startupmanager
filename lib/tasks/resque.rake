# encoding: utf-8
require 'notified_task'

namespace :resque do
  
  NotifiedTask.new :kill_workers => :environment do
    hostname = `hostname`.strip
    pids = []
    
    Resque.workers.each do |worker|
      a = worker.to_s.split(/:/)
      pids << a[1] if (a[0] == hostname)
    end
    
    pid = `cat /tmp/resque_scheduler.pid`
    if pid
      pids << pid
    end    
    
    if pids.size > 0
      system("kill -QUIT #{pids.join(' ')}")
    end
    
  end
  
end

# require "resque/tasks"
# 
# task "resque:setup" => :environment do
#   ENV['QUEUE'] = '*'
# end
# 
# desc "Alias for resque:work (To run workers on Heroku)"
# task "jobs:work" => "resque:work"