require 'sinatra'
require 'omniauth-twitter'
require 'securerandom'
require 'dotenv'
Dotenv.load

enable :sessions
set :session_secret, (ENV['SESSION_SECRET'] || SecureRandom.hex(64))

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
end

get '/' do
  if session[:twitter_info]
    "Hello " + session[:twitter_info][:name] + '. <a href="' + url('/logout') + '">Logout</a>'
  else
    '<a href="' + url('/auth/twitter') + '">Sign in with Twitter</a>'
  end
end

get '/logout' do
  session.clear
  redirect url('/')
end

get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  # Do somthing with the token
  session[:twitter_info] = auth[:info]
  redirect url('/')
end
