require 'bundler'

Bundler.require
Dotenv.load(".env.#{Sinatra::Base.environment}", '.env')

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

require 'tilt/erb'
require 'tilt/sass'
require 'open-uri'
require 'json'

require 'helpers'

require 'app/models'
require 'app/jobs'

# Easy access to models from console
include SeePoliticiansTweet::Models

configure do
  set :database, DB
  set :github_organization, ENV.fetch('GITHUB_ORGANIZATION')

  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET')

  # Get a list of countries in EveryPolitician
  if production?
    countries_json = open('http://data.everypolitician.org/countries.json').read
  else
    countries_json = open('data/countries.json').read
  end

  countries_list = JSON.parse(countries_json)
  countries = {}
  countries_list.each do |country|
    countries[country['url']] = {
      name: country['name'],
      url: country['url'],
      latest_term_csv: country['latest_term_csv']
    }
  end
  set :countries, countries
end

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
  country = settings.countries[params[:country]]
  country_id = Country.insert(
    name: country[:name],
    url: country[:url],
    latest_term_csv: country[:latest_term_csv],
    user_id: current_user.id
  )
  FetchDataJob.perform_async(country_id)
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
