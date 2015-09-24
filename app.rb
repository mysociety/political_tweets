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
  set :use_github, production?
  set :use_twitter, production?
end

require 'helpers'
require 'app/models'
require 'app/jobs'

# Easy access to models from console
include SeePoliticiansTweet::Models

helpers SeePoliticiansTweet::Helpers

use OmniAuth::Builder do
  provider :developer if development?
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
end

use Rack::Flash

get '/*.css' do |filename|
  scss :"sass/#{filename}"
end

get '/' do
  if current_user
    @sites = current_user.sites
  end
  erb :index
end

%w(get post).each do |method|
  send(method, '/auth/:provider/callback') do
    auth = request.env['omniauth.auth']
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
end

get '/logout' do
  session.clear
  flash[:notice] = 'You have been logged out'
  redirect to('/')
end

before '/sites*' do
  redirect to('/auth/twitter') if current_user.nil?
end

post '/sites' do
  begin
    country_slug, legislature_slug = params[:country_legislature].split(':')
    country = settings.countries.find do |country|
      country[:slug] == country_slug
    end
    legislature = country[:legislatures].find do |legislature|
      legislature[:slug] == legislature_slug
    end
    name = country[:name]
    if country[:legislatures].length > 1
      name = "#{name} (#{legislature[:name]})"
    end
    site = current_user.add_site(
      name: name,
      slug: [country[:slug], legislature[:slug]].join('_'),
      github_organization: settings.github_organization,
      latest_term_csv: term_csv(legislature[:legislative_periods].first[:csv])
    )
    FetchDataJob.perform_async(site.id)
    flash[:notice] = 'Your See Politicians Tweet app is being built'
    redirect to('/')
  rescue Sequel::UniqueConstraintViolation
    flash[:alert] = 'There is already a site for this legislature'
    redirect to('/')
  end
end

post '/sites/:id/rebuild' do
  FetchDataJob.perform_async(params[:id])
  flash[:notice] = 'Your rebuild request has been queued'
  redirect to('/')
end

post '/submissions' do
  submission = Submission.create(params[:submission])
  redirect submission.site.url + '/submission-success.html'
end

post '/submissions/:id/moderate' do
  redirect to('/auth/twitter') if current_user.nil?
  if params[:action] == 'accept'
    AcceptSubmissionJob.perform_async(params[:id])
    flash[:notice] = 'Submission accepted'
  else
    submission = Submission[params[:id]]
    submission.delete
    flash[:notice] = 'Submission rejected'
  end
  redirect to('/')
end

post '/event_handler' do
  Site.each { |site| FetchDataJob.perform_async(site.id) }
  'ok'
end
