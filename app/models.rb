DB = Sequel.connect(ENV['DATABASE_URL'], encoding: 'utf-8')

require 'app/models/user'
require 'app/models/country'
require 'app/models/submission'
