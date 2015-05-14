ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../app'

class AppTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_the_homepage_works
    get '/'
    assert last_response.ok?
  end

  def test_choosing_country
    post '/choose-country', country: '/wales'
    assert last_response.redirect?
    assert_equal "http://example.org/auth/twitter", last_response.location
  end
end
