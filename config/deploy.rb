require "dotenv"
Dotenv.load

require "bundler/capistrano"
require "capistrano/ext/multistage"
require File.expand_path("../../lib/capistrano-db-tasks/lib/dbtasks", __FILE__)

set :application, ENV["DEPLOY_APPLICATION"]
set :repository,  ENV["DEPLOY_REPO"]

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :deploy_via, :remote_cache
set :use_sudo, false
set :user, ENV["DEPLOY_USER"]
ssh_options[:forward_agent] = true
# default_run_options[:pty] = true

set :default_environment, { 'PATH' => '$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH' }

# role :web, "your web-server here"                          # Your HTTP server, Apache/etc
# role :app, "your app-server here"                          # This may be the same as your `Web` server
# role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
# role :db,  "your slave db-server here"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

# symlink config files from shared/, and data/
before "deploy:assets:precompile" do
  run "ln -nfs #{shared_path}/config/.env #{release_path}/"
  run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/"
end

after "deploy:create_symlink" do
  cron::reload
end

after "deploy:restart" do
  resque::restart
  deploy::cleanup
end

namespace :deploy do

  namespace :web do  
    # use custom maintenence page, just 'cause we can...
    task :disable, :roles => :web, :except => { :no_release => true } do
      require "erb"
      on_rollback { run "rm #{shared_path}/system/maintenance.html" }

      reason = ENV["REASON"]
      deadline = ENV["UNTIL"]

      template = File.read("app/views/admin/maintenance.html.erb")
      result = ERB.new(template).result(binding)

      put result, "#{shared_path}/system/maintenance.html", :mode => 0644
    end
  end

  task :start do ; end
  task :stop do ; end
  
  task :restart, :roles => :app do
    unicorn::restart
  end

end

namespace :nginx do
  [ :stop, :start, :restart ].each do |t|
    desc "#{t.to_s.capitalize} nginx"
    task t, :roles => :app do
      sudo "/etc/init.d/nginx #{t.to_s}"
    end
  end
end

namespace :cron do
  
  task :reload do
    cron::web
    cron::db
  end
  
  task :web, :roles => :web do
    run "cd #{current_path} && bundle exec whenever --load-file config/schedule_web.rb --set environment=#{environment} --update-crontab #{application}-web" 
  end    

  task :db, :roles => :db do
    run "cd #{current_path} && bundle exec whenever --load-file config/schedule_db.rb --set environment=#{environment} --update-crontab #{application}-db" 
  end
end

namespace :memcached do
  [ :restart ].each do |t|
    desc "#{t.to_s.capitalize} memcached"
    task t, :on_error => :continue, :roles => :db do
      sudo "/etc/init.d/memcached #{t.to_s}"
    end
  end
end
  
namespace :resque do
  task :restart do
    stop
    start
  end
  
  task :stop do
    stop_web
    stop_db
  end
  
  task :start do
    start_web
    start_db
  end
      
  task :start_web, :roles => :web do  
    run "cd #{current_path} && #{rake} BACKGROUND=yes INTERVAL=1 PIDFILE=/tmp/resque_web1.pid QUEUE=lll RAILS_ENV=#{rails_env} environment resque:work 2>&1 | logger -p user.info -t cron-rails 2>&1 >/dev/null"
    if ["production"].include?("#{rails_env}")
      run "cd #{current_path} && #{rake} BACKGROUND=yes INTERVAL=1 PIDFILE=/tmp/resque_web2.pid QUEUE=lll RAILS_ENV=#{rails_env} environment resque:work 2>&1 | logger -p user.info -t cron-rails 2>&1 >/dev/null"
      # run "echo \"bash -l -c 'cd #{current_path} && nice -n 19 #{rake} INTERVAL=1 PIDFILE=/tmp/resque_web3.pid QUEUE=lll RAILS_ENV=#{rails_env} environment resque:work 2>&1 | logger -p user.info -t cron-rails' 2>&1 >/dev/null\" | at 'now + 4 minutes'"
    end
  end

  task :start_db, :roles => :db do  
    run "cd #{current_path} && #{rake} BACKGROUND=yes PIDFILE=/tmp/resque_scheduler.pid RAILS_ENV=#{rails_env} environment resque:scheduler 2>&1 | logger -p user.info -t cron-rails 2>&1 >/dev/null"
    # run "echo \"bash -l -c 'cd #{current_path} && nice -n 19 #{rake} INTERVAL=1 PIDFILE=/tmp/resque_db1.pid QUEUES=ts_delta RAILS_ENV=#{rails_env} environment resque:work 2>&1 | logger -p user.info -t cron-rails' 2>&1 >/dev/null\" | at 'now + 2 minutes'"
    # run "echo \"bash -l -c 'cd #{current_path} && nice -n 19 #{rake} INTERVAL=1 PIDFILE=/tmp/resque2.pid QUEUES=ts_delta,db RAILS_ENV=#{rails_env} environment resque:work 2>&1 | logger -p user.info -t cron-rails'\" | at 'now + 4 minutes' 2>&1 >/dev/null"
  end

  task :stop_web, :roles => :web do
    run "cd #{current_path} && #{rake} RAILS_ENV=#{rails_env} resque:kill_workers" 
  end

  task :stop_db, :roles => :db do
    # if ["production"].include?("#{rails_env}")
    #   run "echo \"bash -l -c 'cd #{current_path} && nice -n 19 #{rake} RAILS_ENV=#{rails_env} environment resque:kill_workers 2>&1 | logger -p user.info -t cron-rails' 2>&1 >/dev/null\" | at 'now + 1 minute'" 
    # end
  end
end

namespace :unicorn do
  task :restart, :on_error => :continue, :roles => :app do
    run "kill -USR2 `cat #{shared_path}/pids/unicorn.pid`"
  end
end

# require "aws/s3"
# namespace :s3 do
#   desc "Bundle code and push to S3: example 'cap staging bundle_app -s version=HEAD'"
#   task :bundle_app do
#     puts "Starting Git archive of #{version}"
#     `git archive -o #{application}.tar #{version}`
#     `rake assets:cache`
#     `find public -name '*-cached*' -exec tar uf #{application}.tar {} \\;`
#     `bzip2 #{application}.tar`
#   
#     s3_upload
#     clean_up
#   end    
#   
#   desc "Upload file to S3"
#   task :s3_upload do
#     # need to have the aws/s3 gem
#     AWS::S3::Base.establish_connection!(
#       :access_key_id     => aws_id,
#       :secret_access_key => aws_key
#     )
#     
#     # upload the new one
#     print "Uploading new one..."
#     AWS::S3::S3Object.store("#{application}_new.tar.bz2", open("#{application}.tar.bz2"), s3_bucket)
#     print "done\n"
#     
#     # rename the old file
#     puts "Renaming old code bundle"
#     if (AWS::S3::S3Object.exists?("#{application}.tar.bz2", s3_bucket))
#       AWS::S3::S3Object.rename "#{application}.tar.bz2", "#{application}-#{Time.now.strftime("%Y-%m-%d-%H%M")}.tar.bz2", s3_bucket
#     end
#     
#     # rename the new file
#     AWS::S3::S3Object.rename "#{application}_new.tar.bz2", "#{application}.tar.bz2", s3_bucket
#   end
#   
#   desc "Clean up old files"
#   task :clean_up do
#     puts "Cleaning up"
#     `rm #{application}.tar.bz2`
#     puts "All done!"
#   end
# end
