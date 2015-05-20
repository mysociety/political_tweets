ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL'] = 'sqlite://db/test.sqlite'

require 'minitest/autorun'
require 'rack/test'
require 'webmock/minitest'

require_relative '../app'

require 'database_cleaner'


DatabaseCleaner.strategy = :transaction

Sequel.extension :migration
db = SeePoliticiansTweet::App.database
Sequel::Migrator.run(db, "db/migrations")
