LeanLaunchLab::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # From http://blog.dynamic50.com/2011/02/15/ssl-on-wildcard-domains-on-heroku-using-godaddy/
  # Every time the app is accessed in production, the access will occur via https and not http
  # config.middleware.use "ForceSSL"

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  config.log_level = :debug

  # Use a different logger for distributed setups
  config.logger = Syslog::Logger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store
#  config.cache_store = :dalli_store, 'localhost:11211', {:expires_in => 24.hours, :socket_timeout => 1, :socket_max_failures => 3, :socket_failure_delay => 1, :down_retry_delay => 1, :namespace => "#{Rails.env}-#{File.read("REVISION").chop}"}

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  #devise In production it must be the actual host of your application
  config.action_mailer.default_url_options = {:protocol => "https", :host => ENV["HOSTNAME"]}

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Choose the compressors to use
  # config.assets.js_compressor  = :uglifier
  # config.assets.css_compressor = :yui

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w(admin.css admin.js landing.css landing.js landing/ie.css v2.js v2.css)
  
  config.assets.initialize_on_precompile = false

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5
end

uri = URI.parse(ENV["REDIS_URL"])
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)