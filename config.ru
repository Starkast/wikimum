require './config/environment'
require './lib/models'
require './lib/controllers'

$stdout.sync = true
$stderr.sync = true

map '/' do
  use Rack::Static, {
    :root => "public",
    :urls => ["/stylesheets", "/images", "/javascripts", "/favicon.ico", "/robots.txt"],
    :cache_control => "public,max-age=#{365 * 24 * 3600}"
  }

  run HomeController
end