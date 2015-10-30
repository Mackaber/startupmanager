#encoding: utf-8
require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.

# Rails 3.1
if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end
# Rails 3.0
# Bundler.require(:default, Rails.env) if defined?(Bundler)

module LeanLaunchLab
  class Application < Rails::Application
    
    config.assets.enabled = true
    config.assets.version = "2.0"
    # config.assets.prefix = "/assets"
    
    # When JSON-encoding a record, don't wrap the attributes in a hash where the
    # key is named after the model
    config.active_record.include_root_in_json = false
    
    config.autoload_paths += %W(#{config.root}/lib)

    # Plugin for ckeditor
    config.autoload_paths += %W(#{config.root}/app/models/ckeditor)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Pacific Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation, :current_password]

    # LLL custom HTML/CSS sanitization
    config.action_view.sanitized_allowed_tags = %w[iframe embed] + %w[
        a abbr b bdo blockquote br caption cite code col colgroup dd del dfn div dl
        dt em figcaption figure h1 h2 h3 h4 h5 h6 hgroup i img ins kbd li mark
        ol p pre q rp rt ruby s samp small strike strong sub sup table tbody td
        tfoot th thead time tr u ul var wbr
      ]
    config.action_view.sanitized_allowed_attributes = %w[style src href]

    config.autoload_paths += %W( #{ config.root }/lib/middleware )
    
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
        :address        => 'smtp.sendgrid.net',
        :port           => '587',
        :authentication => :plain,
        :user_name      => ENV['SENDGRID_USERNAME'],
        :password       => ENV['SENDGRID_PASSWORD'],
        :domain         => 'heroku.com',
        :enable_starttls_auto => true
    }

    def utc_end_of_week
      Time.now.utc.end_of_week.to_date
    end

  end
end

ActionMailer::Base.default ({
  :from => "\"LeanLaunchLab#{Rails.env == 'production' ? "" : " (#{Rails.env})"}\" <#{ENV['EMAIL_NOTIFICATIONS']}>",
  :return_path => ENV["EMAIL_SYSTEM"],
  :reply_to => ENV["EMAIL_SUPPORT"]
})
