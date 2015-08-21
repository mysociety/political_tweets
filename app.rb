require 'bundler'

Bundler.require
Dotenv.load

require 'tilt/erb'
require 'tilt/sass'
require 'open-uri'
require 'json'
require 'active_support/core_ext'

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

configure do
  set :database, lambda {
    ENV['DATABASE_URL'] ||
      "postgres:///seepoliticianstweet_#{environment}"
  }
  set :github_organization, ENV.fetch('GITHUB_ORGANIZATION')

  set :sessions, expire_after: 5.years
  set :session_secret, ENV.fetch('SESSION_SECRET')
  set :countries, lambda {
    countries_json = open('https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/countries.json').read
    JSON.parse(countries_json, symbolize_names: true)
  }
end

require 'helpers'
require 'app/models'
require 'app/jobs'

# Easy access to models from console
include SeePoliticiansTweet::Models

helpers SeePoliticiansTweet::Helpers

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
end

use Rack::Flash

get '/*.css' do |filename|
  scss :"sass/#{filename}"
end

get '/' do
  if current_user
    @countries = current_user.countries
    @submissions = JSON.parse(
      everypolitician.get(
        "/applications/#{ENV['EVERYPOLITICIAN_APP_ID']}/submissions"
      ).body
    )
  end
  erb :index
end

get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  p auth
  user = User.first(twitter_uid: auth[:uid])
  if user
    session[:user_id] = user.id
  else
    session[:user_id] = User.insert(
      twitter_uid: auth[:uid],
      token: auth[:credentials][:token],
      secret: auth[:credentials][:secret]
    )
  end
  flash[:notice] = 'You have successfully logged in with Twitter'
  redirect to('/')
end

get '/logout' do
  session.clear
  flash[:notice] = 'You have been logged out'
  redirect to('/')
end

before '/countries*' do
  redirect to('/auth/twitter') if current_user.nil?
end

post '/countries' do
  country_slug, legislature_slug = params[:country_legislature].split(':')
  country_data = settings.countries.find do |country|
    country[:slug] == country_slug
  end
  legislature = country_data[:legislatures].find do |legislature|
    legislature[:slug] == legislature_slug
  end
  country = current_user.add_country(
    name: country_data[:name],
    url: '/' + country_data[:slug],
    latest_term_csv: legislature[:legislative_periods].first[:csv]
  )
  FetchDataJob.perform_async(country.id)
  flash[:notice] = 'Your See Politicians Tweet app is being built'
  redirect to('/')
end

post '/countries/:id/rebuild' do
  FetchDataJob.perform_async(params[:id])
  flash[:notice] = 'Your rebuild request has been queued'
  redirect to('/')
end

post '/submissions/:id/moderate' do
  AcceptSubmissionJob.perform_async(params[:id]) if params[:action] == 'accept'
  'OK'
end
