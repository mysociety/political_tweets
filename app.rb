require 'sinatra'
require 'omniauth-twitter'
require 'securerandom'
require 'sequel'
require 'open-uri'
require 'json'
require 'resque'
require 'csv'
require 'twitter'

require 'dotenv'
Dotenv.load

# Get a list of countries in EveryPolitician
countries_list = JSON.parse(open('http://data.everypolitician.org/countries.json').read)
$countries = {}
countries_list.each do |country|
  $countries[country['url']] = {
    name: country['name'],
    latest_term_csv: country['latest_term_csv']
  }
end

DB = Sequel.connect(ENV['DATABASE_URL'])

# Resque Jobs

class FetchDataJob
  @queue = :default

  def self.perform(token_id)
    tokens = DB[:tokens]
    token = tokens.where(id: token_id).first
    latest_term_csv = $countries[token[:country]][:latest_term_csv]
    data = open('http://data.everypolitician.org' + latest_term_csv).read
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_KEY']
      config.consumer_secret     = ENV['TWITTER_SECRET']
      config.access_token        = token[:token]
      config.access_token_secret = token[:secret]
    end
    csv = CSV.parse(data, headers: true)
    areas = csv.map { |r| r['area'] }.compact.uniq
    areas.each do |area|
      # Twitter list names must be 25 chars or less
      if area.length > 25
        area = area[0...25]
      end
      list = client.create_list(area)
      list_members = csv.select do |row|
        row['area'] == area && row['twitter']
      end.map { |m| m['twitter'] }
      client.add_list_members(list, list_members)
    end
  end
end

# Sinatra Application

enable :sessions
set :session_secret, (ENV['SESSION_SECRET'] || SecureRandom.hex(64))
set :countries, $countries

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
end

# Step 1 - Select a country
get '/' do
  erb :index
end

# Step 1b - Save country to session and redirect to Twitter OAuth
post '/choose-country' do
  session[:country] = params[:country]
  redirect to('/auth/twitter')
end

# Step 2 Sign in with Twitter
get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  tokens = DB[:tokens]
  token_id = tokens.insert(
    uid: auth[:uid],
    token: auth[:credentials][:token],
    secret: auth[:credentials][:secret],
    country: session[:country]
  )
  session[:token_id] = token_id

  Resque.enqueue(FetchDataJob, token_id)

  redirect to('/success')
end

get '/success' do
  tokens = DB[:tokens]
  @token = tokens.where(id: session[:token_id]).first
  erb :success
end

get '/logout' do
  session.clear
  redirect to('/')
end
