ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'rspec/rails' #rspec-rails needs to load before capybara
require "email_spec"
require "timecop"

require 'capybara/rspec' #cpaybara needs to load after rspec-rails
Capybara.default_driver = :webkit
Capybara.ignore_hidden_elements = false

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

def login_with_email_and_password user, password=user.password
  visit user_session_path
  fill_in 'Email Address', :with => user.email
  fill_in 'Password', :with => password
  click_link('Sign In')
end

# This method is useful to create the "LeanLaunchLab" project up front, before other factory objects are created.
def create_lll_project
  lll_owner = Factory(:lll_owner)
  lll_project = lll_owner.project
  stub LeanLaunchLab::Application.stub(:lll_id).and_return(lll_project.id)
  lll_project
end

# This method is useful to retrofit old tests. It adds the specified user as a member on the LeanLaunchLab project.
def join_the_lll_project user
  member = Member.create :user_id => user.id,
                         :project_id => LeanLaunchLab::Application.lll_id,
                         :level => "Normal",
                         :role_name => "Other"

  member.update_attribute(:join_code, nil)
end


#hacky fix for PGError: ERROR:  permission denied: "RI_ConstraintTrigger_18531" is a system trigger
#when cleaning database between tests
#TODO may be better to use rails3_pg_deferred_constraints gem when we move to Rails 3.1
class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def supports_disable_referential_integrity?
    false
  end
end

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  #email_spec
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # transactional fixtures make Selenium an unhappy camper
  config.use_transactional_fixtures = false

  config.before do
    if example.metadata[:type] == :request
      DatabaseCleaner.strategy = :truncation, {:except => %w[boxes item_statuses]}
    else
      DatabaseCleaner.strategy = :transaction, {:except => %w[boxes item_statuses]}
    end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end

