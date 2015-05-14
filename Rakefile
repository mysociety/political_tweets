require 'dotenv/tasks'
require 'resque/tasks'
require 'rake/testtask'
require_relative './app'

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] => :dotenv do |t, args|
    require "sequel"
    Sequel.extension :migration
    db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "db/migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "db/migrations")
    end
  end
end

task "resque:setup" => :dotenv

Rake::TestTask.new do |t|
  t.pattern = "test/*_test.rb"
end
