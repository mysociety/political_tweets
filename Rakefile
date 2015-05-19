require 'dotenv/tasks'
require 'resque/tasks'
require 'rake/testtask'

task :app => :dotenv do
  require_relative './app'
end

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] => :app do |t, args|
    require "sequel"
    Sequel.extension :migration
    db = SeePoliticiansTweet::App.database
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "db/migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "db/migrations")
    end
  end
end

task "resque:setup" => :app

Rake::TestTask.new do |t|
  t.pattern = "test/*_test.rb"
end
