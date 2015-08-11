# set :job_template, "/bin/bash -l -c ':job'"

job_type :command, %Q{(echo "starting :task"; :task; echo "ending :task") 2>&1 | logger -p user.info -t cron-rails}

job_type :rake, %Q{(echo "starting :task"; cd :path && RAILS_ENV=:environment nice -n 19 bundle exec rake --trace :task; echo "ending :task") 2>&1 | logger -p user.info -t cron-rails}

# every :reboot do
#   rake "INTERVAL=1 PIDFILE=/tmp/resque_web1.pid QUEUE=lll environment resque:work"
# end
# 
# if (environment == "production")
#   every :reboot do
#     rake "INTERVAL=1 PIDFILE=/tmp/resque_web2.pid QUEUE=lll environment resque:work"
#   end
# end
