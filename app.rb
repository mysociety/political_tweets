require 'bundler'

Bundler.require
Dotenv.load(".env.#{Sinatra::Base.environment}", '.env')

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

require 'tilt/erb'
require 'tilt/sass'
require 'open-uri'
require 'json'

require 'jobs'
require 'app/models'

module SeePoliticiansTweet
  # App for creating new SeePoliticiansTweet sites.
  class App < Sinatra::Base
    configure do
      set :database, DB
      set :github_organization, ENV.fetch('GITHUB_ORGANIZATION')

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
      provider :twitter,
               ENV['TWITTER_CONSUMER_KEY'],
               ENV['TWITTER_CONSUMER_SECRET']
    end

    use Rack::Flash

    helpers do
      def current_user
        @current_user ||= User[session[:user_id]]
      end

      # Taken from https://developer.github.com/webhooks/securing/
      def verify_signature(payload_body)
        digest = OpenSSL::Digest.new('sha1')
        signature = 'sha1=' + OpenSSL::HMAC.hexdigest(digest, ENV['GITHUB_WEBHOOK_SECRET'], payload_body)
        return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
      end
    end

    get '/*.css' do |filename|
      scss :"sass/#{filename}"
    end

    get '/' do
      if current_user
        @countries = current_user.countries
        @submissions = Submission.where(country_id: @countries.map(&:id))
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
      Resque.enqueue(FetchDataJob, country_id)
      flash[:notice] = 'Your See Politicians Tweet app is being built'
      redirect to('/')
    end

    post '/countries/:id/rebuild' do
      Resque.enqueue(FetchDataJob, params[:id])
      flash[:notice] = 'Your rebuild request has been queued'
      redirect to('/')
    end

    post '/submissions' do
      submission_id = Submission.insert(params[:submission])
      flash[:notice] = 'Your update has been submitted for approval'
      redirect to("/submissions/#{submission_id}")
    end

    get '/submissions/:id' do
      @submission = Submission[params[:id]]
      erb :new_submission
    end

    post '/submissions/:id/moderate' do
      if params[:action] == 'accept'
        Resque.enqueue(AcceptSubmissionJob, params[:id])
      end
    end

    post '/github_events' do
      request.body.rewind
      payload_body = request.body.read
      verify_signature(payload_body)
      pull_request = JSON.parse(payload_body)
      action = pull_request['action']
      user = pull_request['pull_request']['user']['login']
      # TODO: Better verification of sender
      if action == 'opened' && user == 'seepoliticianstweetbot'
        repo = pull_request['repository']['full_name']
        number = pull_request['number']
        Resque.enqueue(MergeJob, repo, number)
      end
      'OK'
    end
  end
end

# Easy access to models from console
include SeePoliticiansTweet::Models
