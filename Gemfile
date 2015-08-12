source "https://rubygems.org"

gem "rails", "3.2.8"
gem "pg", "0.14.1"

gem "absurdity", "0.2.8"
gem "acts_as_audited", "2.1.0"
gem "aws-sdk", "1.6.9"
gem "cancan", "1.6.8"
gem "ckeditor", "3.6.0"   # TODO upgrade to latest version
gem "devise", "2.1.0"
gem "dotenv-rails"
gem "dynamic_form", "1.1.4"      # error_message_on, etc.
gem "foreigner", "1.2.1"
gem "gon", "4.0.0"
gem "httpclient", "2.2.7"
gem "kaminari", "0.14.1"
gem "jquery-rails", "2.1.3"
gem "nokogiri", "1.5.5"
gem "paperclip", "3.3.0"
gem "prawn", "0.12.0"
gem "redis", "2.2.2"
gem "resque", "1.23.0"
gem "resque-scheduler", "2.0.0", :require => "resque_scheduler"
gem "stripe", :git => "https://github.com/stripe/stripe-ruby"

gem "rake"

group :assets do
  gem "sass-rails", "3.2.5"
  gem "coffee-rails", "3.2.2"
  gem "uglifier", "1.3.0"
end

group :production, :staging do
  gem "dalli", "2.2.1"
  gem "SyslogLogger", "2.0", :require => "syslog/logger"
  gem "therubyracer", "0.12.2"
  gem "unicorn", "4.3.1"
  gem "whenever", "0.7.3"
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

