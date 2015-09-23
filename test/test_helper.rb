if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
  end
end

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'webmock/minitest'

require_relative '../app'

require 'database_cleaner'

DatabaseCleaner.strategy = :truncation

require 'sidekiq/testing'
Sidekiq::Testing.fake!

Sequel.extension :migration
db = Sinatra::Application.database
Sequel::Migrator.run(db, 'db/migrations')

class Minitest::Spec
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end

  before :each do
    Sidekiq::Worker.clear_all
  end
end
