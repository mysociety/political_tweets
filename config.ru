require_relative './app'
require 'resque/server'

run Rack::URLMap.new \
  "/" => SeePoliticiansTweet::App,
  "/resque" => Resque::Server.new
