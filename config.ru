require 'rack/ssl'

require_relative 'config/environment'

map '/' do
  unless ENV.fetch('RACK_ENV') == 'development'
    use Rack::SSL
  end

  use Rack::Static, {
    root: "public",
    urls: ["/stylesheets", "/images", "/javascripts", "/favicon.ico", "/robots.txt"],
    cache_control: "public,max-age=#{365 * 24 * 3600}"
  }

  run PageController

  map '/authorize' do
    run AuthorizeController
  end
end
