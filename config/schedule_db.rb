# set :job_template, "/bin/bash -l -c ':job'"

job_type :command, %Q{(echo "starting :task"; :task; echo "ending :task") 2>&1 | logger -p user.info -t cron-rails}

job_type :rake, %Q{(echo "starting :task"; cd :path && RAILS_ENV=:environment nice -n 19 bundle exec rake --trace :task; echo "ending :task") 2>&1 | logger -p user.info -t cron-rails}

# every :reboot do
#   rake "ts:start ts:index"
# end

# every :reboot do
#   rake "environment resque:scheduler"
#   rake "INTERVAL=1 PIDFILE=/tmp/resque_db1.pid QUEUES=ts_delta,db environment resque:work"
# end

if (environment == "production")
  every :day, :at => "2:00am" do
    command "/data/backups/backup"
  end  
end
