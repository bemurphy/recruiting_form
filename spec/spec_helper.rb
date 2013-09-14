require 'rspec'
require 'capybara'
require 'capybara/dsl'
require 'capybara/rspec'

require_relative "./../app"

# Need to require after app so test mocks load properly
require "malone/test"
require 'sucker_punch/testing/inline'

Capybara.javascript_driver = :selenium

Capybara.app               = Sinatra::Application
Capybara.javascript_driver = :selenium
Capybara.default_wait_time = 10

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Capybara::DSL

  # Create this in couch if it doesn't exist
  Settings::DB_URL = "http://localhost:5984/recruiting_form_test"
end
