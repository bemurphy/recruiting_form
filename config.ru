require "./app"

use Rack::Session::Cookie,
  :key          => 'rack.session',
  :path         => '/',
  :expire_after => 2592000, # In seconds
  :secret       => ENV.fetch('SESSION_SECRET', SecureRandom.hex(32))

use Rack::Protection

run Sinatra::Application
