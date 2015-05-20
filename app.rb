require 'bundler'

Bundler.require
Dotenv.load(".env.#{Sinatra::Base.environment}", '.env')

$LOAD_PATH << File.expand_path('../lib', __FILE__)

require 'tilt/erb'
require 'open-uri'
require 'json'

require 'jobs'

module SeePoliticiansTweet
  class App < Sinatra::Base
    configure do
      set :database, Sequel.connect(ENV['DATABASE_URL'], encoding: 'utf-8')

      enable :sessions
      set :session_secret, ENV.fetch('SESSION_SECRET')

      Resque.redis = ENV['REDISTOGO_URL']

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

    use OmniAuth::Builder do
      provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
    end

    use Rack::Flash

    helpers do
      def database
        settings.database
      end

      def current_user
        @current_user ||= database[:users].first(id: session[:user_id])
      end
    end

    get '/' do
      if current_user
        @countries = database[:countries].where(user_id: session[:user_id])
      end
      erb :index
    end

    get '/auth/:name/callback' do
      auth = request.env['omniauth.auth']
      p auth
      users = database[:users]
      user = users.first(twitter_uid: auth[:uid])
      if user
        session[:user_id] = user[:id]
      else
        session[:user_id] = users.insert(
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

    get '/countries/new' do
      erb :country_new
    end

    post '/countries' do
      country = settings.countries[params[:country]]
      country_id = database[:countries].insert(
        name: country[:name],
        url: country[:url],
        latest_term_csv: country[:latest_term_csv],
        user_id: current_user[:id]
      )
      Resque.enqueue(FetchDataJob, country_id)
      flash[:notice] = 'Your See Politicians Tweet app is being built'
      redirect to("/countries/#{country_id}")
    end

    get '/countries/:id' do
      @country = database[:countries].first(id: params[:id])
      erb :country
    end

    post '/countries/:id/rebuild' do
      Resque.enqueue(FetchDataJob, params[:id])
      flash[:notice] = 'Your rebuild request has been queued'
      redirect to('/')
    end
  end
end
