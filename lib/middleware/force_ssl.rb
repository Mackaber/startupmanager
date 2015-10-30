# encoding: utf-8
class ForceSSL
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if env['HTTPS'] == 'on' || env['HTTP_X_FORWARDED_PROTO'] == 'https'
      @app.call(env)
    else
      [301, {"Location" => req.url.gsub(/^http:/, "https:")}, []]
    end
  end
end