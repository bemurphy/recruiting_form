source "https://rubygems.org"

gem 'erubis', '~> 2.7.0'
gem 'json', '~> 1.8.0'
gem 'malone', '~> 1.0.5'
gem 'rest-client', '~> 1.6.7'
gem 'scrivener', '~> 0.2.0'
gem 'sinatra', '~> 1.4.3'
gem 'sucker_punch', '~> 1.0.2'

# Normally you'd use unicorn on heroku
# but for a simple app this requires less
# config, and we're guaranteed that sucker
# punch will work ok
gem 'thin'

group :development do
  gem 'shotgun'
end

group :test do
  gem 'capybara', '~> 2.1.0'
  gem 'rspec', '~> 2.14.1'
  gem 'selenium-webdriver', '~> 2.35.1'
end
