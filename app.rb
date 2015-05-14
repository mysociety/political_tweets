require 'sinatra'
require 'omniauth-twitter'
require 'securerandom'
require 'sequel'
require 'open-uri'
require 'json'
require 'dotenv'
Dotenv.load

enable :sessions
set :session_secret, (ENV['SESSION_SECRET'] || SecureRandom.hex(64))
countries_list = JSON.parse(open('http://data.everypolitician.org/countries.json').read)
countries = {}
countries_list.each do |country|
  countries[country['url']] = country['name']
end
set :countries, countries

DB = Sequel.connect(ENV['DATABASE_URL'])

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

  # Queue job for generating lists and static site

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
