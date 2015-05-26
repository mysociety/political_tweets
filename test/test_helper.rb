ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'webmock/minitest'

require_relative '../app'

require 'database_cleaner'

DatabaseCleaner.strategy = :transaction

# We don't want to run resque jobs
Resque.inline = true
def Resque.enqueue(*_args)
  true
end

Sequel.extension :migration
db = SeePoliticiansTweet::App.database
Sequel::Migrator.run(db, 'db/migrations')

class Minitest::Spec
  include Rack::Test::Methods

  def app
    SeePoliticiansTweet::App
  end

  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end
