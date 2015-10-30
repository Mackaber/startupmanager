# encoding: utf-8
require 'notified_task'

namespace :memcached do
  
  NotifiedTask.new :restart do
    system("sudo /etc/init.d/memcached restart")
  end
  
end