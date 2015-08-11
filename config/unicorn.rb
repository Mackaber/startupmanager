worker_processes (ENV['RACK_ENV'] == "production" ? 5 : 3)

current = ENV["UNICORN_CURRENT"]
working_directory "#{current}"

shared = ENV["UNICORN_SHARED"]

# This loads the application in the master process before forking
# worker processes
# Read more about it here:
# http://unicorn.bogomips.org/Unicorn/Configurator.html
preload_app true

timeout 300

# This is where we specify the socket.
# We will point the upstream Nginx module to this socket later on
listen "/tmp/unicorn.sock", :backlog => 1024

pid "#{shared}/pids/unicorn.pid"

# Set the path of the log files inside the log folder of the testapp
stderr_path "#{shared}/log/unicorn.stderr.log"
stdout_path "#{shared}/log/unicorn.stdout.log"

before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "#{current}/Gemfile"
end

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
  
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
  
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
  Rails.cache.reset
end
