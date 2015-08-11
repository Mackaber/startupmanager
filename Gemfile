source "https://rubygems.org"

gem "rails", "~>3.2"
gem "pg"

gem "absurdity"
gem "acts_as_audited"
gem "aws-sdk"
gem "cancan"
gem "ckeditor", "3.6.0"   # TODO upgrade to latest version
gem "devise"
gem "dotenv"
gem "dynamic_form"      # error_message_on, etc.
gem "foreigner"
gem "gon"
gem "httpclient"
gem "kaminari"
gem "jquery-rails", "~>2.1.3"
gem "nokogiri", "<1.6"
gem "paperclip"
gem "prawn"
gem "redis", "<3.0"
gem "resque"
gem "resque-scheduler", :require => "resque_scheduler"
gem "stripe", :git => "https://github.com/stripe/stripe-ruby"

gem "rake"

group :assets do
  gem "sass-rails"
  gem "coffee-rails"
  gem "uglifier"
end

group :production, :staging do
  gem "dalli"
  gem "SyslogLogger", :require => "syslog/logger"
  gem "therubyracer"
  gem "unicorn"
  gem "whenever"
end

group :development do
  gem "capistrano", "<3.0"
  gem "capistrano-ext"
end

# group :development, :test do
#   gem "autotest-rails"
#   gem "awesome_print"
#   gem "capybara-webkit"
#   gem "database_cleaner"
#   gem "email_spec"
#   gem "escape_utils"
#   gem "factory_girl_rails"
#   gem "rspec-rails"
#   gem "ruby-debug19", :require => "ruby-debug"
#   gem "timecop"
#   gem "wirble"
# end

